#!/usr/bin/env python3
"""Confere os limites de caracteres da App Store nos textos de store/ficha-app-store.md.

A Apple rejeita o envio com o campo estourado, e conferir no navegador é fácil de
esquecer. Uso: python3 store/checar-limites.py
"""

import re
import sys
from pathlib import Path

LIMITES = {
    "Nome do app": 30,
    "Subtítulo": 30,
    "Palavras-chave": 100,
    "Texto promocional": 170,
    "Descrição": 4000,
    "Novidades desta versão": 4000,
}

ficha = Path(__file__).parent / "ficha-app-store.md"
texto = ficha.read_text(encoding="utf-8")

# Cada campo é um "## Título" seguido, mais adiante, do primeiro bloco ```...```
falhas = 0
for campo, limite in LIMITES.items():
    secao = re.search(rf"^## {re.escape(campo)}\b.*?^```\n(.*?)^```", texto,
                      re.MULTILINE | re.DOTALL)
    if not secao:
        print(f"  ?  {campo}: não encontrei o bloco de texto")
        falhas += 1
        continue

    conteudo = secao.group(1).rstrip("\n")
    n = len(conteudo)
    ok = n <= limite
    falhas += 0 if ok else 1
    print(f"  {'OK ' if ok else 'ERRO'} {campo}: {n}/{limite}")

sys.exit(1 if falhas else 0)
