#!/usr/bin/env python3
"""Extrai o sentido de cada substantivo da base. Passo A da Fase 2.

O problema
----------
Quase todo erro achado nesta base não foi de vocabulário, foi de **identidade da
palavra**. `der Rock` (pl. Röcke) virou *pedra* porque alguém leu o *rock* inglês;
`das Gift` virou *presente*; `der Most` virou *mais*. O tradutor não errou o português —
errou qual palavra estava traduzindo.

Desambiguar é trabalho **neutro de idioma**. Decidir que `der Rock, pl. Röcke` é a peça
de roupa não tem nada a ver com português, espanhol ou francês. Feito uma vez, serve
todos. Feito por idioma, o mesmo erro reaparece N vezes e precisa ser caçado N vezes —
sem falante nativo para reclamar em francês.

Por que a glosa é escrita EM ALEMÃO
------------------------------------
Esta é a decisão que faz o arquivo valer alguma coisa. Se o sentido fosse escrito em
inglês, `der Rock` receberia a glosa *skirt* — e no passo seguinte o modelo traduziria
a partir do inglês, que é **exatamente o pivô que produziu todos estes erros**. Uma
definição alemã de uma palavra alemã não tem por onde pivotar: `Kleidungsstück, das von
der Hüfte abwärts getragen wird` só pode virar *saia*, *skirt*, *falda* ou *jupe*.

O plural é o sinal mais forte e vai no prompt junto: `Röcke` ≠ `Rocks`, `Tage` ≠ `Tags`.
Foi ele que denunciou cada homógrafo, e é ele que impede o modelo de repetir o erro.

Saída
-----
`tools/senses.json`, chaveado por `ARTIGO|palavra` — a mesma chave qualificada de
`corrections.json`, porque `der Tag` e `das Tag` são palavras diferentes e precisam de
sentidos diferentes.

    "DER|Rock": {
      "glosse": "Kleidungsstück",
      "definition": "Kleidungsstück, das von der Hüfte abwärts getragen wird",
      "bereich": "Kleidung",
      "mehrdeutig": true,
      "verwechselbar_mit": "englisch 'rock' (Stein, Musik)"
    }

Retomável: cada lote é gravado assim que chega, e uma nova execução só pede as chaves
que faltam. Interromper no meio não perde trabalho.

Uso
---
    python3 tools/senses.py --amostra 40        # vê o prompt, não chama nada
    python3 tools/senses.py --lote 40           # extrai o que falta
    python3 tools/senses.py --so-faltantes      # quantas faltam
"""

import argparse
import json
import os
import sys
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'docs/data/GermanNouns.json'
CORR = ROOT / 'tools/corrections.json'
SAIDA = ROOT / 'tools/senses.json'

SCHEMA = 1
MODELO = 'claude-sonnet-5'

CAMPOS = ('glosse', 'definition', 'bereich', 'mehrdeutig', 'verwechselbar_mit')

INSTRUCOES = """\
Du bist Lexikograf für ein Lernprogramm, das deutsche Artikel unterrichtet.

Für jedes Substantiv unten bestimmst du die **Bedeutung** — nicht die Übersetzung.
Schreibe ausschließlich auf Deutsch. Eine Übersetzung in irgendeine andere Sprache ist
ein Fehler.

Der Plural ist dein wichtigstes Signal zur Unterscheidung: "der Rock, Pl. Röcke" ist ein
Kleidungsstück; "Pl. Rocks" wäre die Musik. "der Tag, Pl. Tage" ist die Zeiteinheit;
"das Tag, Pl. Tags" ist die Markierung. Artikel und Plural gehören zusammen — wenn sie
sich widersprechen, richte dich nach dem Plural.

Felder pro Eintrag:
- "glosse": ein einziges deutsches Synonym oder Oberbegriff, klein geschrieben wenn möglich
- "definition": ein kurzer deutscher Definitionssatz, höchstens 12 Wörter, ohne das
  Stichwort selbst zu wiederholen
- "bereich": Sachgebiet in einem Wort (z. B. Kleidung, Recht, Medizin, Technik, Alltag)
- "mehrdeutig": true, wenn das Wort im Deutschen mehrere gängige Bedeutungen hat
- "verwechselbar_mit": wenn die Schreibweise mit einem englischen Wort anderer Bedeutung
  zusammenfällt oder mit einem anderen deutschen Wort verwechselt wird, nenne es kurz;
  sonst ""

Antworte mit einem einzigen JSON-Objekt: Schlüssel exakt wie vorgegeben, keine weiteren
Schlüssel, kein Text außerhalb des JSON.
"""


def carregar_base():
    dados = json.loads(BASE.read_text(encoding='utf-8'))
    if isinstance(dados, list):
        sys.exit('Base no formato antigo. Rode apply-corrections.py primeiro.')
    return dados


def carregar_saida(base):
    """Lê o que já foi extraído, descartando tudo se a base mudou de identidade.

    O arquivo de sentidos é chaveado, não alinhado por índice, então ele sobrevive a
    reordenações. Mas se o digest mudou, palavras entraram ou saíram — manter sentidos
    de uma base que não existe mais é como carregar um pacote fora de sincronia.
    """
    if not SAIDA.exists():
        return {}
    dados = json.loads(SAIDA.read_text(encoding='utf-8'))
    if dados.get('base_digest') != base['digest']:
        print(f'! base mudou ({dados.get("base_digest")} -> {base["digest"]}); '
              'sentidos de palavras que sumiram serão ignorados')
    return dados.get('senses', {})


def gravar(senses, base):
    SAIDA.write_text(json.dumps({
        'schema': SCHEMA,
        'base_digest': base['digest'],
        'count': len(senses),
        '_doc': 'Sentidos em alemão, chaveados por ARTIGO|palavra. Gerado por tools/senses.py.',
        'senses': dict(sorted(senses.items())),
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def montar_prompt(lote):
    linhas = [
        f"{noun['article'].lower()} {noun['word']}"
        + (f", Pl. {noun['plural']}" if noun.get('plural') else ', kein Plural')
        for noun in lote
    ]
    chaves = [f"{n['article']}|{n['word']}" for n in lote]
    return (
        INSTRUCOES
        + '\nSubstantive:\n'
        + '\n'.join(f'{chave}  ->  {linha}' for chave, linha in zip(chaves, linhas))
    )


def validar(resposta, lote):
    """Rejeita o lote inteiro se vier torto. Meio lote é pior que nenhum."""
    esperadas = {f"{n['article']}|{n['word']}" for n in lote}
    if not isinstance(resposta, dict):
        raise ValueError('resposta não é um objeto JSON')

    faltando = esperadas - set(resposta)
    sobrando = set(resposta) - esperadas
    if faltando or sobrando:
        raise ValueError(f'chaves faltando: {sorted(faltando)[:3]}; '
                         f'sobrando: {sorted(sobrando)[:3]}')

    for chave, entrada in resposta.items():
        if not isinstance(entrada, dict):
            raise ValueError(f'{chave}: entrada não é objeto')
        if set(entrada) != set(CAMPOS):
            raise ValueError(f'{chave}: campos {sorted(entrada)} != {sorted(CAMPOS)}')
        if not entrada['glosse'] or not entrada['definition']:
            raise ValueError(f'{chave}: glosse ou definition vazia')
        if not isinstance(entrada['mehrdeutig'], bool):
            raise ValueError(f'{chave}: mehrdeutig não é booleano')
    return resposta


def chaves_do_gabarito():
    """As palavras que têm correção humana em pt-BR — o gabarito da Fase 2.

    Rodar só elas custa centavos e responde a pergunta que importa antes de gastar com
    as 11.694: este modelo consegue desambiguar as palavras que já erraram uma vez?
    """
    corrections = json.loads(CORR.read_text(encoding='utf-8'))
    fix = {k: v for k, v in corrections.get('fix', {}).items() if not k.startswith('_')}
    tabela = fix if all(isinstance(v, str) for v in fix.values()) else fix.get('pt-BR', {})
    return {k: v for k, v in tabela.items() if not k.startswith('_')}


def eh_fatal(erro):
    """Erros que não melhoram na segunda tentativa.

    Chave inválida, sem saldo, modelo que não existe: insistir só queima tempo e
    esconde a causa atrás de 293 tracebacks iguais. Já limite de taxa e queda de rede
    são temporários — esses valem uma nova execução, que retoma de onde parou.
    """
    try:
        import anthropic
    except ImportError:
        return False
    if isinstance(erro, (anthropic.AuthenticationError, anthropic.PermissionDeniedError)):
        return True
    return isinstance(erro, anthropic.NotFoundError)


def chamar_modelo(prompt, modelo=MODELO):
    """Backend único: API da Anthropic, temperatura 0.

    Fica isolado de propósito — todo o resto deste arquivo (prompt, validação, retomada)
    é independente de quem gera, e é onde está o valor.
    """
    try:
        import anthropic
    except ImportError:
        sys.exit('pacote `anthropic` não instalado:  python3 -m pip install anthropic')
    if not os.environ.get('ANTHROPIC_API_KEY'):
        sys.exit('ANTHROPIC_API_KEY não está no ambiente.')

    cliente = anthropic.Anthropic()
    resposta = cliente.messages.create(
        model=modelo,
        max_tokens=8000,
        temperature=0,
        messages=[{'role': 'user', 'content': prompt}],
    )
    texto = resposta.content[0].text.strip()
    if texto.startswith('```'):
        texto = texto.split('\n', 1)[1].rsplit('```', 1)[0]
    return json.loads(texto)


def main():
    global SAIDA
    ap = argparse.ArgumentParser()
    ap.add_argument('--lote', type=int, default=40, help='substantivos por chamada')
    ap.add_argument('--max-lotes', type=int, default=0, help='0 = até acabar')
    ap.add_argument('--paralelo', type=int, default=6, help='chamadas simultâneas')
    ap.add_argument('--modelo', default=MODELO)
    ap.add_argument('--saida', type=Path, help=f'padrão: {SAIDA.relative_to(ROOT)}')
    ap.add_argument('--gabarito', action='store_true',
                    help='só as palavras com correção humana em pt-BR')
    ap.add_argument('--amostra', type=int, metavar='N',
                    help='imprime o prompt de N substantivos e sai, sem chamar nada')
    ap.add_argument('--so-faltantes', action='store_true', help='conta e sai')
    args = ap.parse_args()

    if args.saida:
        SAIDA = args.saida

    base = carregar_base()
    senses = carregar_saida(base)

    universo = base['nouns']
    if args.gabarito:
        gabarito = chaves_do_gabarito()
        universo = [
            n for n in base['nouns']
            if f"{n['article']}|{n['word']}" in gabarito or n['word'] in gabarito
        ]

    faltantes = [n for n in universo if f"{n['article']}|{n['word']}" not in senses]

    escopo = 'gabarito' if args.gabarito else 'base'
    print(f'{escopo} {len(universo)}, sentidos {len(senses)}, faltam {len(faltantes)}'
          f'   [{args.modelo}]')
    if args.so_faltantes:
        return 0
    if args.amostra:
        print('\n' + '=' * 70)
        print(montar_prompt(faltantes[:args.amostra]))
        return 0
    if not faltantes:
        print('Nada a fazer.')
        return 0

    lotes = [faltantes[i:i + args.lote] for i in range(0, len(faltantes), args.lote)]
    if args.max_lotes:
        lotes = lotes[:args.max_lotes]

    # Em série, 293 lotes levariam quase duas horas. Os lotes são independentes por
    # construção — cada um só depende do seu próprio prompt —, então paralelizar é
    # seguro. A trava protege só a escrita: gravar a cada lote é o que torna a
    # interrupção barata, e duas threads gravando ao mesmo tempo corromperiam o arquivo.
    trava = threading.Lock()
    concluidos = falhas = 0

    def processar(indice_lote):
        numero, lote = indice_lote
        try:
            return numero, validar(chamar_modelo(montar_prompt(lote), args.modelo), lote), None
        except (ValueError, json.JSONDecodeError) as erro:
            return numero, None, erro
        except Exception as erro:                       # noqa: BLE001 — rede e API
            return numero, None, erro

    with ThreadPoolExecutor(max_workers=args.paralelo) as executor:
        futuros = [executor.submit(processar, item) for item in enumerate(lotes, 1)]
        for futuro in as_completed(futuros):
            numero, resposta, erro = futuro.result()
            with trava:
                # Chave inválida, sem saldo ou modelo inexistente não melhoram na
                # segunda tentativa: erram os 293 lotes igual. Parar na primeira poupa
                # a espera e deixa a causa legível, em vez de um traceback de thread.
                if erro is not None and eh_fatal(erro):
                    print(f'\n! {erro}')
                    print('! nada a tentar de novo; parando.')
                    for pendente in futuros:
                        pendente.cancel()
                    break
                if erro is not None:
                    falhas += 1
                    print(f'  lote {numero}: descartado — {erro}')
                    continue
                falhas = 0
                concluidos += 1
                senses.update(resposta)
                gravar(senses, base)
                if concluidos % 10 == 0 or concluidos == len(lotes):
                    print(f'  {concluidos}/{len(lotes)} lotes  ({len(senses)} sentidos)')

    if falhas:
        print(f'! {falhas} lotes ficaram de fora; rode de novo para pegar só eles')
    gravar(senses, base)
    pedidas = {f"{n['article']}|{n['word']}" for n in universo}
    print(f'\n{SAIDA} com {len(pedidas & set(senses))}/{len(pedidas)} sentidos do {escopo}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
