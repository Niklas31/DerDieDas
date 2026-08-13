#!/usr/bin/env python3
"""Extrai os campos da ficha da App Store para arquivos-texto puros.

A ficha em Markdown continua sendo a única fonte: ela traz os limites de caracteres, o
porquê de cada escolha e as instruções de preenchimento. O que sai daqui é só o texto,
sem crases nem cabeçalhos, para copiar direto no App Store Connect sem levar junto a
marcação.

Os nomes de arquivo e a pasta seguem o layout do fastlane (`metadata/<locale>/campo.txt`).
Hoje isso não muda nada, mas quando entrarem espanhol e francês a árvore já está no
formato que o `fastlane deliver` lê — e a migração custa zero.

Uso:  python3 tools/extrair-ficha.py
"""

import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
FICHA = RAIZ / 'store' / 'ficha-app-store.md'
DESTINO = RAIZ / 'store' / 'metadata' / 'pt-BR'

# Título da seção na ficha -> nome do arquivo no padrão do fastlane.
CAMPOS = {
    'Nome do app': 'name.txt',
    'Subtítulo': 'subtitle.txt',
    'Palavras-chave': 'keywords.txt',
    'Texto promocional': 'promotional_text.txt',
    'Descrição': 'description.txt',
    'Novidades desta versão': 'release_notes.txt',
}

# Estes não vivem em bloco de código na ficha, e sim numa tabela — mais legível lá,
# mas é preciso repetir aqui. Se divergirem, a ficha manda.
FIXOS = {
    'support_url.txt': 'https://derdiedas.app.br',
    'marketing_url.txt': 'https://derdiedas.app.br',
    'privacy_url.txt': 'https://derdiedas.app.br/privacidade.html',
}


def blocos(texto):
    """Devolve {título da seção: primeiro bloco de código dela}."""
    achados = {}
    # Cada seção vai de um "## " até o próximo. O `?=` não consome o delimitador, senão
    # a seção seguinte se perderia.
    for secao in re.split(r'^## ', texto, flags=re.MULTILINE)[1:]:
        titulo = secao.split('\n', 1)[0]
        # O título carrega o limite depois de "·" — "Descrição  · limite 4000".
        titulo = titulo.split('·')[0].strip()
        bloco = re.search(r'^```\n(.*?)\n```', secao, flags=re.MULTILINE | re.DOTALL)
        if bloco:
            achados[titulo] = bloco.group(1)
    return achados


def main():
    if not FICHA.exists():
        sys.exit(f'ficha não encontrada em {FICHA}')

    achados = blocos(FICHA.read_text(encoding='utf-8'))
    DESTINO.mkdir(parents=True, exist_ok=True)

    faltando = [t for t in CAMPOS if t not in achados]
    if faltando:
        sys.exit('seções sem bloco de código na ficha: ' + ', '.join(faltando))

    for titulo, arquivo in CAMPOS.items():
        conteudo = achados[titulo]
        (DESTINO / arquivo).write_text(conteudo + '\n', encoding='utf-8')
        print(f'  {arquivo:22s} {len(conteudo):>5} caracteres')

    for arquivo, conteudo in FIXOS.items():
        (DESTINO / arquivo).write_text(conteudo + '\n', encoding='utf-8')
        print(f'  {arquivo:22s} {len(conteudo):>5} caracteres')

    print(f'\nem {DESTINO.relative_to(RAIZ)}')


if __name__ == '__main__':
    main()
