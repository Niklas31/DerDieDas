#!/usr/bin/env python3
"""Gera a base alemã e os pacotes de tradução a partir das fontes em tools/.

Entradas (editáveis à mão):
    tools/translations/<lang>.json   traduções chaveadas por ARTIGO|palavra
    tools/corrections.json           correções revisadas — têm a palavra final

Saídas (geradas, não editar):
    docs/data/GermanNouns.json       fatos do alemão: artigo, palavra, plural
    docs/data/lang/<lang>.json       traduções alinhadas por índice à base

Por que separado
----------------
A base veio de tradução automática e passou por várias revisões; o alemão em si é
estável. Separar deixa o download menor — 97 KB de base + 55 KB por idioma contra
171 KB do arquivo único de antes — e cada idioma novo passa a custar 55 KB baixados
sob demanda, em vez de inchar o arquivo de todo mundo.

Alinhamento por índice, e não por chave
---------------------------------------
O pacote é um array puro de strings, na mesma ordem da base. Custa metade do tamanho
de um mapa chaveado (55 KB contra 112 KB), porque o mapa repetiria a palavra alemã nos
dois arquivos e o gzip não enxerga entre respostas HTTP diferentes.

Isso só é seguro porque a ordem é determinística — `(word.lower(), article)`, injetiva
sobre as 11.694 linhas — e existe **um único escritor**: este arquivo. O `digest` torna
a invariante verificável: quem carrega compara, e um pacote fora de sincronia é
descartado inteiro em vez de aplicado torto.

Uso: python3 tools/apply-corrections.py
"""

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'docs/data/GermanNouns.json'
PACKS_DIR = ROOT / 'docs/data/lang'
CORR = ROOT / 'tools/corrections.json'
SOURCES_DIR = ROOT / 'tools/translations'

SCHEMA = 2
ORDER = 'word.lower(),article'

# Abaixo disto o idioma está em andamento, não pronto — e não vira pacote publicável.
COBERTURA_MINIMA = 99.0


def sem_comentarios(tabela):
    """As chaves iniciadas por `_` são documentação embutida no JSON."""
    return {k: v for k, v in tabela.items() if not k.startswith('_')}


def procurar(tabela, noun):
    """Acha a correção para este substantivo, aceitando chave qualificada.

    `"Tag"` vale para todos os sentidos; `"DER|Tag"` vale só para um. Sem isso,
    corrigir "das Tag = etiqueta" sobrescreveria também "der Tag = dia" — o mesmo
    erro de chavear pela grafia que criou o problema que estas correções consertam.
    """
    qualificada = f"{noun['article']}|{noun['word']}"
    if qualificada in tabela:
        return qualificada, tabela[qualificada]
    if noun['word'] in tabela:
        return noun['word'], tabela[noun['word']]
    return None, None


def calcular_digest(nouns):
    conteudo = '\n'.join(f"{n['article']}|{n['word']}" for n in nouns)
    return hashlib.sha256(conteudo.encode('utf-8')).hexdigest()[:16]


def carregar_base_atual():
    """Lê a base, aceitando tanto o formato antigo (array puro) quanto o v2."""
    dados = json.loads(BASE.read_text(encoding='utf-8'))
    return dados if isinstance(dados, list) else dados['nouns']


def tabelas_de_fix(corrections):
    """`fix` por idioma. Aceita o formato plano antigo como se fosse pt-BR."""
    fix = corrections.get('fix', {})
    limpo = sem_comentarios(fix)
    if limpo and all(isinstance(v, str) for v in limpo.values()):
        return {'pt-BR': limpo}
    return {lang: sem_comentarios(tab) for lang, tab in limpo.items()}


def main():
    nouns = carregar_base_atual()
    corrections = json.loads(CORR.read_text(encoding='utf-8'))

    fixes_por_idioma = tabelas_de_fix(corrections)
    article_fixes = sem_comentarios(corrections.get('fix_article', {}))
    plural_fixes = sem_comentarios(corrections.get('fix_plural', {}))
    additions = list(sem_comentarios(corrections.get('add', {})).values())
    removals = {
        word
        for key, words in corrections['remove'].items()
        if not key.startswith('_')
        for word in words
    }

    antes = len(nouns)
    artigos_aplicados, plurais_aplicados = set(), set()

    # --- fatos do alemão -----------------------------------------------------
    resultado = []
    for noun in nouns:
        if noun['word'] in removals:
            continue
        entrada = {'article': noun['article'], 'word': noun['word'], 'plural': noun.get('plural')}
        if entrada['word'] in article_fixes:
            entrada['article'] = article_fixes[entrada['word']]
            artigos_aplicados.add(entrada['word'])
        chave, valor = procurar(plural_fixes, entrada)
        if chave:
            entrada['plural'] = valor
            plurais_aplicados.add(chave)
        resultado.append(entrada)

    # A identidade é ARTIGO|palavra, então um "der Tag" convive com o "das Tag".
    existentes = {(n['article'], n['word']) for n in resultado}
    adicionadas = 0
    for novo in additions:
        chave = (novo['article'], novo['word'])
        if chave in existentes:
            continue
        resultado.append({'article': novo['article'], 'word': novo['word'],
                          'plural': novo.get('plural')})
        existentes.add(chave)
        adicionadas += 1

    resultado.sort(key=lambda n: (n['word'].lower(), n['article']))
    digest = calcular_digest(resultado)

    BASE.write_text(json.dumps({
        'schema': SCHEMA,
        'order': ORDER,
        'count': len(resultado),
        'digest': digest,
        'nouns': resultado,
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    print(f'Base: {antes} -> {len(resultado)} substantivos   digest {digest}')
    print(f'  artigos corrigidos: {len(artigos_aplicados)}/{len(article_fixes)}')
    print(f'  plurais corrigidos: {len(plurais_aplicados)}/{len(plural_fixes)}')
    print(f'  adicionados:        {adicionadas}/{len(additions)}')
    print(f'  removidos:          {antes - (len(resultado) - adicionadas)}')

    # --- pacotes de tradução -------------------------------------------------
    #
    # Todos são regerados na mesma execução: é isso que faz o digest ser verdadeiro
    # por construção, em vez de uma promessa que alguém precisa lembrar de manter.
    PACKS_DIR.mkdir(parents=True, exist_ok=True)
    fontes = sorted(SOURCES_DIR.glob('*.json'))
    if not fontes:
        print('\n! nenhuma fonte em tools/translations/ — nenhum pacote gerado')
        return

    print()
    for fonte in fontes:
        lang = fonte.stem
        dados = json.loads(fonte.read_text(encoding='utf-8'))
        traducoes = sem_comentarios(dados.get('translations', {}))
        fixes = fixes_por_idioma.get(lang, {})

        alinhado, sem_traducao, corrigidas = [], 0, set()
        for noun in resultado:
            chave, valor = procurar(fixes, noun)
            if chave:
                corrigidas.add(chave)
            else:
                valor = traducoes.get(f"{noun['article']}|{noun['word']}", '')
            if not valor:
                sem_traducao += 1
            alinhado.append(valor)

        faltando = sorted(set(fixes) - corrigidas)
        cobertura = 100 * (len(alinhado) - sem_traducao) / len(alinhado)

        # Um idioma pela metade não é publicável, e o modo de falha é silencioso: o
        # pacote carrega, o digest confere, e o usuário simplesmente vê palavras sem
        # tradução sem entender por quê. Gerar um idioma leva horas e é retomável, então
        # é normal a fonte estar incompleta no meio do caminho — o que não pode é isso
        # virar artefato publicado por descuido.
        if cobertura < COBERTURA_MINIMA:
            print(f'  {lang}: {cobertura:.1f}% traduzidas — PACOTE NÃO GERADO '
                  f'(mínimo {COBERTURA_MINIMA}%)')
            print(f'      idioma em andamento: {sem_traducao} palavras ainda sem tradução')
            if not (PACKS_DIR / f'{lang}.json').exists():
                print(f'      docs/data/lang/{lang}.json não existe e continua não existindo')
            else:
                print(f'      docs/data/lang/{lang}.json ficou como estava')
            continue

        (PACKS_DIR / f'{lang}.json').write_text(json.dumps({
            'schema': SCHEMA,
            'language': lang,
            'count': len(alinhado),
            'digest': digest,
            'translations': alinhado,
        }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

        print(f'  {lang}: {len(alinhado)} entradas, {cobertura:.1f}% traduzidas, '
              f'{len(corrigidas)}/{len(fixes)} correções aplicadas')
        if sem_traducao:
            print(f'      {sem_traducao} sem tradução')
        if faltando:
            print(f'      ! correções sem alvo: {", ".join(faltando)}')


if __name__ == '__main__':
    main()
