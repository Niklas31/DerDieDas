#!/usr/bin/env python3
"""Audita artigo e plural da base contra o german-nouns. Não altera nada.

Por que auditar em vez de regerar
----------------------------------
A base foi deduplicada **por grafia**, e o alemão tem homônimos de gêneros diferentes:
`der Tag` (dia) e `das Tag` (o *tag* do inglês). Quando dois sentidos colidiam sobrava um
registro só — às vezes com o artigo de um, o plural de outro e a tradução de um terceiro.

A tentação é regerar tudo do german-nouns. **Não regere.** Foi medido: o corte de
frequência sozinho deixa passar 2.733 entradas que o pipeline original do Colab filtrava
com regex — locuções (`Platz der Vereinten Nationen`), sufixos soltos (`-ung`), fragmentos
(`DAS Gif`). Dessas, 2.231 viriam sem tradução. A base regerada fica pior que a curada.

Pior ainda seria adicionar em bloco todos os gêneros que a fonte conhece: ela registra
variantes raras e regionais (`das Bereich`, `das Kiefer`) ao lado das corretas. Num app
que ensina artigos para A1–B1, dizer que "DAS Bereich" vale é ensinar errado.

Então este script **só aponta candidatos**. A decisão é humana, e o que for confirmado
entra em `tools/corrections.json`.

Uso
---
    python3 -m venv .venv && .venv/bin/pip install german-nouns
    .venv/bin/python tools/audit-base.py
"""

import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'docs/data/GermanNouns.json'
SAIDA = ROOT / 'tools/audit-report.json'

ARTIGO = {'m': 'DER', 'f': 'DIE', 'n': 'DAS'}
POS_DESCARTADAS = {'Nachname', 'Vorname', 'Toponym', 'Familienname', 'Abkürzung'}

# Quantos compostos precisam concordar para o voto valer. Abaixo disso é ruído.
MIN_COMPOSTOS = 4
CONCORDANCIA = 0.85


def ler_fonte(palavras):
    """(artigo, palavra) -> plural, só para as grafias que já estão na base."""
    try:
        import german_nouns
    except ImportError:
        sys.exit('german-nouns não instalado. Veja o cabeçalho deste arquivo.')

    csv.field_size_limit(10 ** 7)
    caminho = Path(list(german_nouns.__path__)[0]) / 'nouns.csv'
    fonte = {}
    with caminho.open(encoding='utf-8') as f:
        for linha in csv.DictReader(f):
            lemma = (linha.get('lemma') or '').strip()
            if lemma not in palavras:
                continue
            pos = {p.strip() for p in (linha.get('pos') or '').split(',')}
            if pos & POS_DESCARTADAS or 'Substantiv' not in pos:
                continue
            generos = {
                linha[c].strip()
                for c in ('genus', 'genus 1', 'genus 2', 'genus 3', 'genus 4')
                if linha.get(c, '').strip()
            }
            plural = next(
                (linha[c].strip()
                 for c in ('nominativ plural', 'nominativ plural 1', 'nominativ plural*')
                 if linha.get(c, '').strip()),
                None,
            )
            for g in generos:
                if artigo := ARTIGO.get(g):
                    fonte.setdefault((artigo, lemma), plural)
    return fonte


def votacao_por_compostos(nouns):
    """Em alemão o composto herda o artigo do último elemento.

    27 compostos em `-tag` marcados DER provam que `Tag` é DER. Foi assim que
    apareceram Fall, Ort, Bereich, Bruch, Rolle, Wende, Steuer, Kiefer, Bauer e
    Moment com o artigo errado.

    Cuidado com falso positivo: `-ion` em "Adaption" é sufixo, não o substantivo
    `Ion`. Por isso o resultado é candidato, não veredito.
    """
    por_palavra = {n['word']: n for n in nouns}
    minusculas = {w.lower(): w for w in por_palavra}

    votos = defaultdict(lambda: defaultdict(list))
    for n in nouns:
        w = n['word']
        wl = w.lower()
        for corte in range(3, len(wl) - 2):
            nucleo = minusculas.get(wl[corte:])
            if nucleo and nucleo != w:
                votos[nucleo][n['article']].append(w)
                break

    suspeitos = []
    for nucleo, artigos in votos.items():
        total = sum(len(v) for v in artigos.values())
        if total < MIN_COMPOSTOS:
            continue
        dominante, lista = max(artigos.items(), key=lambda kv: len(kv[1]))
        atual = por_palavra[nucleo]['article']
        if atual != dominante and len(lista) / total >= CONCORDANCIA:
            suspeitos.append({
                'palavra': nucleo,
                'base': atual,
                'compostos_dizem': dominante,
                'votos': f'{len(lista)}/{total}',
                'traducao': por_palavra[nucleo]['portugueseTranslation'],
                'exemplos': lista[:4],
            })
    return sorted(suspeitos, key=lambda s: -int(s['votos'].split('/')[1]))


def main():
    nouns = json.loads(BASE.read_text(encoding='utf-8'))
    tem = {(n['article'], n['word']) for n in nouns}
    por_palavra = {n['word']: n for n in nouns}

    print(f'base: {len(nouns)} substantivos\n')

    print('lendo german-nouns...')
    fonte = ler_fonte(set(por_palavra))

    # 1. Sentidos que a deduplicação engoliu.
    faltando = []
    for (artigo, palavra), plural in sorted(fonte.items()):
        if (artigo, palavra) not in tem:
            atual = por_palavra[palavra]
            faltando.append({
                'falta': f'{artigo} {palavra}',
                'plural': plural,
                'base_tem': f"{atual['article']} {palavra} = {atual['portugueseTranslation']}",
            })

    # 2. Artigo divergente da fonte, quando a fonte só conhece um gênero.
    generos_por_palavra = defaultdict(set)
    for artigo, palavra in fonte:
        generos_por_palavra[palavra].add(artigo)
    divergentes = [
        {
            'palavra': p,
            'base': por_palavra[p]['article'],
            'fonte': next(iter(g)),
            'traducao': por_palavra[p]['portugueseTranslation'],
        }
        for p, g in generos_por_palavra.items()
        if len(g) == 1 and por_palavra[p]['article'] not in g
    ]

    # 3. Votação pelos compostos — pega o que a fonte não resolve.
    suspeitos = votacao_por_compostos(nouns)

    print(f'\n1. sentidos ausentes (homônimos engolidos):  {len(faltando)}')
    print(f'2. artigo divergente da fonte:               {len(divergentes)}')
    print(f'3. artigo suspeito pelos compostos:          {len(suspeitos)}')

    if divergentes:
        print('\n   os mais preocupantes (fonte conhece um gênero só, e não é o da base):')
        for d in divergentes[:15]:
            print(f"     {d['base']} {d['palavra']:20} fonte diz {d['fonte']:4} — {d['traducao'][:30]}")

    SAIDA.write_text(json.dumps({
        'sentidos_ausentes': faltando,
        'artigo_divergente_da_fonte': divergentes,
        'artigo_suspeito_por_compostos': suspeitos,
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'\nrelatório em {SAIDA.relative_to(ROOT)}')
    print('Nada foi alterado. Confirme caso a caso e registre em tools/corrections.json.')


if __name__ == '__main__':
    main()
