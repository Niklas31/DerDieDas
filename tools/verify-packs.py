#!/usr/bin/env python3
"""Verifica os pacotes de tradução contra a base. Não altera nada.

Duas categorias, com consequências diferentes
---------------------------------------------
**Checagens duras** — digest, contagem e o *portão das correções*. Falhar em qualquer
uma encerra com status 1: o pacote está errado de um jeito que não se revisa, se
conserta. São elas que impedem um pacote torto de ir ao ar.

**Sinais suaves** — heurísticas que apontam candidatos a erro. Nenhuma delas prova nada
sozinha; todas vão para `tools/review/<lang>.json` para revisão humana. Um sinal que
dispara demais é pior que um sinal que não existe, então os limiares foram calibrados
contra o pt-BR curado, onde as respostas certas já são conhecidas.

O portão das correções
----------------------
`tools/corrections.json` guarda decisões humanas conquistadas uma a uma — `Rock` é saia,
`das Tag` é etiqueta, `der Most` é mosto. Elas são o gabarito: um gerador de traduções
que não as reproduz está errado, e não adianta gerar um segundo idioma com ele. É a
checagem mais barata que existe, porque o gabarito já está pronto e num idioma que o
dono do projeto lê.

Por que este arquivo não importa `apply-corrections.py`
-------------------------------------------------------
Um verificador que compartilha código com o gerador herda os bugs do gerador. Se a busca
de chave voltasse a casar `Tag` com `der Tag` e `das Tag` ao mesmo tempo — o bug que
originou a chave qualificada —, um verificador que reusasse aquela função concordaria
alegremente. `procurar_correcao` abaixo é reescrita de propósito. A duplicação é o teste.

Uso
---
    python3 tools/verify-packs.py            # todos os pacotes
    python3 tools/verify-packs.py en         # só um
"""

import json
import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'docs/data/GermanNouns.json'
PACKS_DIR = ROOT / 'docs/data/lang'
CORR = ROOT / 'tools/corrections.json'
REVIEW_DIR = ROOT / 'tools/review'

# --- limiares dos sinais suaves ------------------------------------------------
#
# Calibrados contra o pt-BR curado: acima destes valores o ruído afoga o sinal e a
# lista deixa de ser revisada, que é o modo de falha real destas heurísticas.

COLAPSO_MIN = 6          # palavras alemãs distintas caindo na mesma tradução
MAX_SENTIDOS = 3         # sentidos separados por ' / '
MAX_PALAVRAS = 5         # palavras num único sentido
MAX_CARACTERES = 60

# Artigos e preposições contraídas do português: uma tradução não começa com eles.
PREFIXO_ARTIGO = re.compile(r'^(o|a|os|as|um|uma|uns|umas)\s', re.IGNORECASE)

# Traduções legitimamente idênticas à palavra alemã. Manter curta e justificada —
# esta allowlist é o lugar onde um erro real se esconde para sempre.
IGUAL_AO_ALEMAO_OK = {
    'Ego',        # empréstimo latino, idêntico nos dois idiomas
    'Alibi',
    'Aroma',
    'Cello',
    'Drama',
    'Gala',
    'Karma',
    'Mantra',
    'Radar',
    'Sofa',
    'Taxi',
    'Ultimatum',
    'Veto',
    'Visa',
}


def normalizar(texto):
    """Mesma normalização do app: sem acento, minúscula, ß vira ss."""
    sem_acento = ''.join(
        c for c in unicodedata.normalize('NFD', texto) if not unicodedata.combining(c)
    )
    return sem_acento.lower().replace('ß', 'ss')


def sem_comentarios(tabela):
    return {k: v for k, v in tabela.items() if not k.startswith('_')}


def procurar_correcao(tabela, article, word):
    """Reescrita de propósito — veja o cabeçalho. Qualificada vence a simples."""
    if f'{article}|{word}' in tabela:
        return tabela[f'{article}|{word}']
    if word in tabela:
        return tabela[word]
    return None


def tabelas_de_fix(corrections):
    fix = sem_comentarios(corrections.get('fix', {}))
    if fix and all(isinstance(v, str) for v in fix.values()):
        return {'pt-BR': fix}
    return {lang: sem_comentarios(tab) for lang, tab in fix.items()}


# --- checagens duras -----------------------------------------------------------

def checar_estrutura(base, pack, lang):
    """Digest e contagem. Um pacote que falha aqui é descartado inteiro pelo app."""
    problemas = []
    if pack.get('digest') != base['digest']:
        problemas.append(
            f"digest {pack.get('digest')!r} != base {base['digest']!r} — "
            'o app descartaria este pacote inteiro'
        )
    if pack.get('count') != base['count']:
        problemas.append(f"count {pack.get('count')} != base {base['count']}")
    if len(pack.get('translations', [])) != base['count']:
        problemas.append(
            f"{len(pack.get('translations', []))} traduções para {base['count']} substantivos"
        )
    if pack.get('language') != lang:
        problemas.append(f"language {pack.get('language')!r} != {lang!r} (nome do arquivo)")
    return problemas


def checar_portao(base, traducoes, fixes):
    """As correções humanas precisam estar no artefato final, literalmente.

    Não basta a correção existir em corrections.json: o que vai para o aparelho é o
    pacote, e é ele que precisa dizer 'saia'. Esta checagem lê o produto, não a receita.
    """
    faltando = []
    alvos = defaultdict(list)
    for noun, traducao in zip(base['nouns'], traducoes):
        esperado = procurar_correcao(fixes, noun['article'], noun['word'])
        if esperado is None:
            continue
        chave = f"{noun['article']}|{noun['word']}"
        alvos[chave] = esperado
        if traducao != esperado:
            faltando.append({
                'palavra': chave,
                'esperado': esperado,
                'encontrado': traducao,
            })
    # Uma correção sem alvo nenhum é tão grave quanto uma não aplicada: a palavra
    # sumiu da base e a decisão humana virou letra morta sem ninguém perceber.
    grafias = {f"{n['article']}|{n['word']}" for n in base['nouns']}
    palavras = {n['word'] for n in base['nouns']}
    orfas = [
        chave for chave in fixes
        if chave not in grafias and chave not in palavras
    ]
    return faltando, orfas, len(alvos)


# --- sinais suaves -------------------------------------------------------------

def sinal_igual_ao_alemao(base, traducoes):
    """Tradução igual à palavra alemã, em dois níveis de suspeita.

    O empréstimo legítimo costuma passar pela ortografia do destino — `Album` vira
    *álbum*, `Gas` vira *gás*. Essa adaptação é assinatura de tradução de verdade. Já o
    valor idêntico letra por letra é o que o tradutor devolve quando **não traduziu**:
    foi assim que `der Bach` (riacho) ficou *bach* e `der Baumgarten` (pomar) ficou
    *baumgarten*.

    Separar os dois põe a densidade de erro na lista menor. Nenhum dos níveis prova nada
    sozinho — `backup` e `bingo` são idênticos e estão certos —, e é por isso que este
    sinal fica muito mais barato depois que `tools/senses.json` existir: com o sentido em
    mãos, "a tradução reflete a glosa?" é uma pergunta mecânica, não um chute.
    """
    exatos, adaptados = [], []
    for noun, traducao in zip(base['nouns'], traducoes):
        if not traducao or noun['word'] in IGUAL_AO_ALEMAO_OK:
            continue
        if normalizar(traducao) != normalizar(noun['word']):
            continue
        item = {'palavra': f"{noun['article']}|{noun['word']}", 'traducao': traducao}
        if traducao.lower() == noun['word'].lower():
            exatos.append(item)
        else:
            adaptados.append(item)
    return exatos, adaptados


def sinal_pivo_ingles(base, traducoes, ingles):
    """Valor idêntico ao do pacote inglês, num pacote que não é inglês.

    É a impressão digital do pivô alemão->inglês->destino: quando o modelo lê o sentido
    inglês da palavra alemã, a tradução "espanhola" sai em inglês, igualzinha.
    """
    achados = []
    for noun, traducao, en in zip(base['nouns'], traducoes, ingles):
        if not traducao or not en:
            continue
        if normalizar(traducao) == normalizar(en):
            achados.append({
                'palavra': f"{noun['article']}|{noun['word']}",
                'traducao': traducao,
                'ingles': en,
            })
    return achados


def sinal_colapso(base, traducoes):
    """Muitas palavras alemãs distintas caindo na mesma string.

    Foi assim que `fan -> fã` apareceu: Fächer, Lüfter e Ventilator viraram todos 'fã'
    porque o inglês *fan* cobre leque e ventilador. Sinônimos legítimos existem, então
    isto é candidato, não veredito.
    """
    grupos = defaultdict(list)
    for noun, traducao in zip(base['nouns'], traducoes):
        if traducao:
            grupos[traducao].append(f"{noun['article']}|{noun['word']}")
    return [
        {'traducao': t, 'quantidade': len(ws), 'palavras': ws}
        for t, ws in sorted(grupos.items(), key=lambda kv: -len(kv[1]))
        if len(ws) >= COLAPSO_MIN
    ]


def sinal_forma(base, traducoes):
    """Contrato de estilo. Sem ele os pacotes ficam incoerentes entre si.

    Uma 'tradução' de dez palavras é uma definição disfarçada, e um valor começando com
    'o ' ou 'a ' é o modelo devolvendo sintagma em vez de lema.
    """
    achados = []
    for noun, traducao in zip(base['nouns'], traducoes):
        if not traducao:
            continue
        motivos = []
        sentidos = [s.strip() for s in traducao.split(' / ')]
        if len(sentidos) > MAX_SENTIDOS:
            motivos.append(f'{len(sentidos)} sentidos')
        if len(traducao) > MAX_CARACTERES:
            motivos.append(f'{len(traducao)} caracteres')
        if any(len(s.split()) > MAX_PALAVRAS for s in sentidos):
            motivos.append('sentido longo demais')
        if any(PREFIXO_ARTIGO.match(s) for s in sentidos):
            motivos.append('começa com artigo')
        if traducao.rstrip().endswith(('.', ';', ',')):
            motivos.append('pontuação final')
        if traducao != traducao.strip():
            motivos.append('espaço nas bordas')
        if any(s and s[0].isupper() for s in sentidos):
            motivos.append('maiúscula inicial')
        if motivos:
            achados.append({
                'palavra': f"{noun['article']}|{noun['word']}",
                'traducao': traducao,
                'motivos': motivos,
            })
    return achados


def sinal_homonimos_iguais(base, traducoes):
    """Mesma grafia com artigos diferentes precisa ter traduções diferentes.

    `der Tag` é dia e `das Tag` é etiqueta — se os dois trouxerem a mesma string, um
    deles está errado com certeza, porque a única razão de existirem dois registros é
    serem palavras diferentes. Precisão alta e custo zero.
    """
    por_grafia = defaultdict(list)
    for noun, traducao in zip(base['nouns'], traducoes):
        por_grafia[noun['word']].append((noun['article'], traducao))
    achados = []
    for word, entradas in por_grafia.items():
        if len(entradas) < 2:
            continue
        distintas = {t for _, t in entradas if t}
        if len(distintas) < len(entradas):
            achados.append({
                'palavra': word,
                'entradas': [{'artigo': a, 'traducao': t} for a, t in entradas],
            })
    return achados


def sinal_ausentes(base, traducoes):
    return [
        f"{noun['article']}|{noun['word']}"
        for noun, traducao in zip(base['nouns'], traducoes)
        if not traducao
    ]


# --- execução ------------------------------------------------------------------

def verificar(lang, base, corrections, ingles):
    caminho = PACKS_DIR / f'{lang}.json'
    pack = json.loads(caminho.read_text(encoding='utf-8'))
    traducoes = pack.get('translations', [])

    duros = checar_estrutura(base, pack, lang)
    if duros:
        print(f'\n{lang}: ESTRUTURA INVÁLIDA')
        for problema in duros:
            print(f'  ! {problema}')
        return False

    fixes = tabelas_de_fix(corrections).get(lang, {})
    faltando, orfas, aplicadas = checar_portao(base, traducoes, fixes)

    exatos, adaptados = sinal_igual_ao_alemao(base, traducoes)
    revisao = {
        'nao_traduzido': exatos,
        'cognato_adaptado': adaptados,
        'homonimos_com_traducao_igual': sinal_homonimos_iguais(base, traducoes),
        'colapso': sinal_colapso(base, traducoes),
        'forma': sinal_forma(base, traducoes),
        'sem_traducao': sinal_ausentes(base, traducoes),
    }
    if ingles is not None and lang != 'en':
        revisao['pivo_ingles'] = sinal_pivo_ingles(base, traducoes, ingles)

    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    (REVIEW_DIR / f'{lang}.json').write_text(
        json.dumps(revisao, ensure_ascii=False, indent=2) + '\n', encoding='utf-8'
    )

    ok = not faltando and not orfas
    print(f'\n{lang}: {pack["count"]} entradas, digest confere')
    print(f'  portão: {aplicadas - len(faltando)}/{aplicadas} correções no artefato')
    for item in faltando:
        print(f'    ! {item["palavra"]}: esperava {item["esperado"]!r}, '
              f'achou {item["encontrado"]!r}')
    for chave in orfas:
        print(f'    ! correção órfã (palavra não existe na base): {chave}')

    for nome, achados in revisao.items():
        if achados:
            print(f'  ~ {nome}: {len(achados)}')
    print(f'  revisão em tools/review/{lang}.json')
    return ok


def main():
    base = json.loads(BASE.read_text(encoding='utf-8'))
    if isinstance(base, list):
        sys.exit('Base no formato antigo (array puro). Rode apply-corrections.py primeiro.')
    corrections = json.loads(CORR.read_text(encoding='utf-8'))

    pedidos = sys.argv[1:]
    disponiveis = sorted(p.stem for p in PACKS_DIR.glob('*.json'))
    langs = pedidos or disponiveis
    for lang in langs:
        if lang not in disponiveis:
            sys.exit(f'pacote {lang} não existe em {PACKS_DIR}')

    # O pacote inglês é referência do sinal de pivô; carregado uma vez só.
    ingles = None
    if 'en' in disponiveis:
        ingles = json.loads((PACKS_DIR / 'en.json').read_text(encoding='utf-8'))['translations']

    print(f'Base: {base["count"]} substantivos, digest {base["digest"]}')
    resultados = [verificar(lang, base, corrections, ingles) for lang in langs]

    if all(resultados):
        print('\nTodas as checagens duras passaram.')
        return 0
    print('\nFALHOU. Nenhum pacote deve ir ao ar assim.')
    return 1


if __name__ == '__main__':
    sys.exit(main())
