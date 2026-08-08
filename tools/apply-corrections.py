#!/usr/bin/env python3
"""Aplica tools/corrections.json sobre docs/data/GermanNouns.json.

A base veio de tradução automática (Google Tradutor, via Colab) e tem dois tipos de
problema: traduções erradas e palavras que não servem para aprender vocabulário
(nomes próprios, marcas, siglas). Este script corrige ambos de forma reproduzível —
reportes novos que chegarem pelo botão do app entram no mesmo corrections.json.

Uso: python3 tools/apply-corrections.py
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'docs/data/GermanNouns.json'
CORR = ROOT / 'tools/corrections.json'


def main():
    nouns = json.loads(BASE.read_text(encoding='utf-8'))
    corrections = json.loads(CORR.read_text(encoding='utf-8'))

    fixes = {k: v for k, v in corrections['fix'].items() if not k.startswith('_')}
    # O artigo também erra: a lista de origem traz casos como "der Mode", cujo
    # plural (Moden) denuncia que o substantivo é feminino.
    article_fixes = {
        k: v for k, v in corrections.get('fix_article', {}).items()
        if not k.startswith('_')
    }
    # O plural erra junto: a deduplicação da lista de origem fundiu homônimos de
    # gêneros diferentes, misturando o artigo de um sentido com o plural de outro
    # ("das Bauer" com plural "Bauer" é a gaiola; o agricultor é "der Bauer/Bauern").
    plural_fixes = {
        k: v for k, v in corrections.get('fix_plural', {}).items()
        if not k.startswith('_')
    }
    # E há palavras que a deduplicação simplesmente engoliu: "der Tag" (dia) sumiu
    # porque o "das Tag" do inglês ocupou a chave.
    additions = [
        v for k, v in corrections.get('add', {}).items() if not k.startswith('_')
    ]
    removals = {
        word
        for key, words in corrections['remove'].items()
        if not key.startswith('_')
        for word in words
    }

    antes = len(nouns)
    aplicadas, artigos_aplicados, plurais_aplicados = set(), set(), set()

    resultado = []
    for noun in nouns:
        word = noun['word']
        if word in removals:
            continue
        if word in fixes:
            noun['portugueseTranslation'] = fixes[word]
            aplicadas.add(word)
        if word in article_fixes:
            noun['article'] = article_fixes[word]
            artigos_aplicados.add(word)
        if word in plural_fixes:
            noun['plural'] = plural_fixes[word]
            plurais_aplicados.add(word)
        resultado.append(noun)

    # A identidade é ARTIGO|palavra, então um "der Tag" convive com o "das Tag".
    existentes = {(n['article'], n['word']) for n in resultado}
    adicionadas = 0
    for novo in additions:
        if (novo['article'], novo['word']) in existentes:
            continue
        resultado.append(novo)
        adicionadas += 1

    resultado.sort(key=lambda n: (n['word'].lower(), n['article']))

    nao_encontradas = sorted(set(fixes) - aplicadas)
    artigos_nao_encontrados = sorted(set(article_fixes) - artigos_aplicados)
    plurais_nao_encontrados = sorted(set(plural_fixes) - plurais_aplicados)
    removidas = len(nouns) - (len(resultado) - adicionadas)
    nao_removidas = sorted(removals - {n['word'] for n in nouns} & removals)

    BASE.write_text(
        json.dumps(resultado, ensure_ascii=False, indent=2) + '\n', encoding='utf-8'
    )

    print(f'Base: {antes} -> {len(resultado)} substantivos')
    print(f'  traduções corrigidas: {len(aplicadas)}/{len(fixes)}')
    print(f'  artigos corrigidos:   {len(artigos_aplicados)}/{len(article_fixes)}')
    print(f'  plurais corrigidos:   {len(plurais_aplicados)}/{len(plural_fixes)}')
    print(f'  adicionados:          {adicionadas}/{len(additions)}')
    print(f'  removidos:            {removidas}/{len(removals)} listados')
    if nao_encontradas:
        print(f'\n  ! não encontrados para corrigir: {", ".join(nao_encontradas)}')
    if artigos_nao_encontrados:
        print(f'  ! artigos não encontrados: {", ".join(artigos_nao_encontrados)}')
    if plurais_nao_encontrados:
        print(f'  ! plurais não encontrados: {", ".join(plurais_nao_encontrados)}')
    if nao_removidas:
        print(f'  ! listados para remover mas ausentes: {len(nao_removidas)}')


if __name__ == '__main__':
    main()
