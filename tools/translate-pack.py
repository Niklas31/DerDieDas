#!/usr/bin/env python3
"""Traduz a base alemã para um idioma, com desambiguação no mesmo passe.

Por que num passe só
--------------------
A primeira versão deste trabalho tinha duas etapas: extrair o sentido de cada palavra
num arquivo neutro de idioma, e depois verter o sentido. Medimos e não se pagou. Mesmo
no conjunto mais difícil da base — as palavras que já erraram uma vez — só metade é
ambígua; o resto é `Handtuch`, `Seife`, `Abendessen`, onde um modelo atual acerta direto
e a definição alemã intermediária não resolvia nada.

Então o sentido virou **subproduto**: o modelo devolve a tradução e, junto, se a palavra
é ambígua e com o que ela se confunde. Custa um passe por idioma — que é o que você
precisa fazer de qualquer jeito — e os sinais se acumulam em `tools/signals.json`. Quando
chegar o terceiro idioma, as armadilhas já foram catalogadas pelos dois primeiros, de
graça.

O que impede o pivô
-------------------
Todo erro grave desta base veio de traduzir alemão→inglês→destino: `der Rock` virou
*pedra*, `das Gift` virou *presente*, `das Tag` virou *dia*. Três coisas no prompt
atacam isso: as instruções são escritas **em alemão**, o **plural vai junto com cada
palavra** (`Röcke` ≠ `Rocks`, `Tage` ≠ `Tags`), e o modelo precisa **declarar** a
confusão quando a grafia coincide com uma palavra inglesa.

Decisão humana é terminal
-------------------------
Chaves presentes em `corrections.json` → `fix[idioma]` **nunca** são pedidas nem
sobrescritas. Foram conquistadas uma a uma, e são o gabarito contra o qual o resultado é
medido por `verify-packs.py`.

Dois modos de gerar
-------------------
O valor deste arquivo é o prompt, a validação e a fusão — não quem chama o modelo.

    # via subagentes (usa o plano, não gasta API)
    python3 tools/translate-pack.py pt-BR --emitir
    #   ... um agente por lote escreve tools/batches/pt-BR/NNN.json ...
    python3 tools/translate-pack.py pt-BR --ingerir

    # via API
    python3 tools/translate-pack.py pt-BR --api

Depois: `python3 tools/apply-corrections.py && python3 tools/verify-packs.py`
"""

import argparse
import json
import re
import sys
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'docs/data/GermanNouns.json'
CORR = ROOT / 'tools/corrections.json'
FONTES = ROOT / 'tools/translations'
SINAIS = ROOT / 'tools/signals.json'
LOTES = ROOT / 'tools/batches'

MODELO = 'claude-sonnet-5'
CAMPOS = ('uebersetzung', 'mehrdeutig', 'verwechselbar_mit')

# Nome do idioma **em alemão**: o prompt inteiro é em alemão para manter o modelo
# ancorado na palavra de origem, então o alvo também se nomeia ali.
IDIOMAS = {
    'pt-BR': 'brasilianisches Portugiesisch',
    'pt': 'Portugiesisch',
    'en': 'Englisch',
    'es': 'Spanisch',
    'fr': 'Französisch',
    'it': 'Italienisch',
    'nl': 'Niederländisch',
}

INSTRUCOES = """\
Du übersetzt deutsche Substantive für ein Lernprogramm, das die deutschen Artikel
unterrichtet. Zielsprache: {idioma}.

Entscheidend ist nicht die Übersetzung selbst, sondern **welches Wort** du übersetzt.
Der Plural steht bei jedem Eintrag und ist dein wichtigstes Signal: "der Rock, Pl. Röcke"
ist ein Kleidungsstück, "Pl. Rocks" wäre die Musik. "der Tag, Pl. Tage" ist die
Zeiteinheit, "das Tag, Pl. Tags" die Markierung. Widersprechen sich Artikel und Plural,
richte dich nach dem Plural.

Viele dieser Wörter sind mit englischen Wörtern völlig anderer Bedeutung
schreibgleich — Gift, Rock, Most, First, Dose, Sage, Band, Alter. Übersetze **niemals**
über das Englische. Du übersetzt das deutsche Wort direkt in die Zielsprache.

Felder pro Eintrag:
- "uebersetzung": die Übersetzung in {idioma}. Kleinschreibung, ohne Artikel der
  Zielsprache, kein ganzer Satz. Mehrere Bedeutungen mit " / " trennen, höchstens drei,
  wichtigste zuerst. Gibt es keine brauchbare Entsprechung, nimm die gebräuchlichste
  Umschreibung in höchstens vier Wörtern.
- "mehrdeutig": true, wenn das deutsche Wort mehrere gängige Bedeutungen hat
- "verwechselbar_mit": kurz auf Deutsch, wenn die Schreibweise mit einem englischen Wort
  anderer Bedeutung oder mit einem anderen deutschen Wort zusammenfällt; sonst ""

Antworte mit einem einzigen JSON-Objekt: Schlüssel exakt wie vorgegeben, keine weiteren
Schlüssel, kein Text außerhalb des JSON.
"""


def sem_comentarios(tabela):
    return {k: v for k, v in tabela.items() if not k.startswith('_')}


def carregar_base():
    dados = json.loads(BASE.read_text(encoding='utf-8'))
    if isinstance(dados, list):
        sys.exit('Base no formato antigo. Rode apply-corrections.py primeiro.')
    return dados


def carregar_fix(lang):
    corrections = json.loads(CORR.read_text(encoding='utf-8'))
    fix = sem_comentarios(corrections.get('fix', {}))
    if fix and all(isinstance(v, str) for v in fix.values()):
        return sem_comentarios(fix) if lang == 'pt-BR' else {}
    return sem_comentarios(fix.get(lang, {}))


def carregar_fonte(lang):
    caminho = FONTES / f'{lang}.json'
    if not caminho.exists():
        return {}
    return sem_comentarios(json.loads(caminho.read_text(encoding='utf-8')).get('translations', {}))


def gravar_fonte(lang, traducoes):
    FONTES.mkdir(parents=True, exist_ok=True)
    (FONTES / f'{lang}.json').write_text(json.dumps({
        '_doc': f'Traduções em {lang}, chaveadas por ARTIGO|palavra. É isto que se edita; '
                f'docs/data/lang/{lang}.json é o artefato gerado.',
        'language': lang,
        'translations': dict(sorted(traducoes.items())),
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def carregar_sinais():
    if not SINAIS.exists():
        return {}
    return json.loads(SINAIS.read_text(encoding='utf-8')).get('signals', {})


def gravar_sinais(sinais):
    SINAIS.write_text(json.dumps({
        '_doc': 'Ambiguidade e confusão por palavra alemã, subproduto da tradução. '
                'Neutro de idioma: acumula entre os pacotes e serve os próximos.',
        'count': len(sinais),
        'signals': dict(sorted(sinais.items())),
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def pendentes(base, lang):
    """Palavras sem tradução — descontando as que já têm decisão humana.

    Uma chave em `fix` não é pedida ao modelo: ela já foi decidida, e `apply-corrections`
    a aplica por cima de qualquer coisa que estiver na fonte. Pedi-la seria pagar por uma
    resposta que vai ser descartada.
    """
    fonte = carregar_fonte(lang)
    fix = carregar_fix(lang)
    faltando = []
    for noun in base['nouns']:
        chave = f"{noun['article']}|{noun['word']}"
        if chave in fonte and fonte[chave]:
            continue
        if chave in fix or noun['word'] in fix:
            continue
        faltando.append(noun)
    return faltando


def palavras_do_gabarito(base, lang):
    """As palavras que têm decisão humana — o portão.

    Elas são justamente as que `pendentes()` nunca pede ao modelo, porque a correção já
    vence na fusão. Só que é exatamente por isso que servem de prova: são as que já
    erraram uma vez, a resposta certa está guardada, e a comparação é de string contra
    string, sem interpretação no meio. Um gerador que não reproduz estas não deve gerar
    idioma nenhum.
    """
    fix = carregar_fix(lang)
    return [
        n for n in base['nouns']
        if f"{n['article']}|{n['word']}" in fix or n['word'] in fix
    ]


def sentidos(texto):
    """Quebra uma tradução em sentidos comparáveis.

    Descarta o que está entre parênteses — `cumeeira (do telhado)` e `cumeeira` são a
    mesma palavra com nota de contexto — e normaliza espaço e caixa.
    """
    limpo = re.sub(r'\([^)]*\)', ' ', texto)
    return {
        ' '.join(parte.lower().split())
        for parte in limpo.split(' / ')
        if parte.strip()
    }


def compativel(alvo, obtido):
    """Compartilha pelo menos um sentido com a decisão humana?

    A igualdade de string é a métrica errada aqui, e medi-la ensinou isso: ela reprova
    `coletânea / antologia` com o mesmo peso com que reprovaria `pedra` para `Rock`. O
    erro que este trabalho existe para pegar é catastrófico — a palavra errada —, não
    estilístico. Um sentido em comum separa os dois casos: `saia / anágua` passa,
    `pedra` não.

    Também aceita quando um contém o outro, para `templo budista` × `templo budista
    tailandês`, onde o modelo apenas especificou mais.
    """
    a, b = sentidos(alvo), sentidos(obtido)
    if a & b:
        return True
    return any(x in y or y in x for x in a for y in b)


def conferir_portao(base, lang, pasta):
    """Compara o que o modelo devolveu com a decisão humana guardada."""
    fix = carregar_fix(lang)
    indice = {f"{n['article']}|{n['word']}": n for n in base['nouns']}
    chaves = json.loads((pasta / 'chaves.json').read_text(encoding='utf-8'))

    def esperado(chave):
        return fix.get(chave) or fix.get(chave.split('|', 1)[1])

    iguais, proximas, divergentes, sem_resposta = [], [], [], 0
    for numero in sorted(chaves):
        arquivo = pasta / f'{numero}.json'
        if not arquivo.exists():
            sem_resposta += len(chaves[numero])
            continue
        lote = [indice[c] for c in chaves[numero] if c in indice]
        try:
            dados = validar(json.loads(arquivo.read_text(encoding='utf-8')), lote)
        except (ValueError, json.JSONDecodeError) as erro:
            print(f'  lote {numero}: rejeitado — {erro}')
            sem_resposta += len(chaves[numero])
            continue
        for chave, entrada in dados.items():
            obtido = entrada['uebersetzung'].strip()
            alvo = esperado(chave)
            if obtido == alvo:
                iguais.append((chave, alvo, obtido))
            elif compativel(alvo, obtido):
                proximas.append((chave, alvo, obtido))
            else:
                divergentes.append((chave, alvo, obtido))

    total = len(iguais) + len(proximas) + len(divergentes)
    print(f'\nPORTÃO {lang}: {total} palavras do gabarito')
    print(f'  idênticas            {len(iguais)}')
    print(f'  sentido em comum     {len(proximas)}')
    print(f'  SEM sentido em comum {len(divergentes)}')
    if sem_resposta:
        print(f'  sem resposta         {sem_resposta}')

    if proximas:
        print('\n  variação de estilo, não de sentido:')
        for chave, alvo, obtido in sorted(proximas):
            print(f'    {chave:24} {alvo!r}  ->  {obtido!r}')

    if divergentes:
        print('\n  SEM sentido em comum — é aqui que mora o erro grave, julgue uma a uma:')
        for chave, alvo, obtido in sorted(divergentes):
            print(f'    {chave:24} curada {alvo!r}')
            print(f'    {"":24} modelo {obtido!r}')

    # Só a ausência de sentido em comum reprova. Sinônimo e sentido a mais são ruído
    # esperado entre dois tradutores competentes.
    return not divergentes


def montar_prompt(lote, lang):
    idioma = IDIOMAS.get(lang, lang)
    linhas = [
        f"{n['article']}|{n['word']}  ->  {n['article'].lower()} {n['word']}"
        + (f", Pl. {n['plural']}" if n.get('plural') else ', kein Plural')
        for n in lote
    ]
    return INSTRUCOES.format(idioma=idioma) + '\nSubstantive:\n' + '\n'.join(linhas)


# Artigo inicial: por idioma, e **removido** em vez de rejeitado.
#
# A primeira versão juntava os artigos de todos os idiomas numa expressão só e reprovava
# o lote inteiro. Custou 21 lotes de 60 palavras: `un working group` bateu no artigo
# francês dentro de uma tradução inglesa, e `das Ich -> the self` foi reprovado sendo
# que em inglês o artigo é obrigatório ali.
#
# Reprovar 60 palavras por causa de uma é desproporcional, e a correção certa é trivial:
# tirar o artigo dá o lema que se queria — `a fatura` vira `fatura`, `the afterlife` vira
# `afterlife`. Continua valendo para o caso que motivou a regra, sem punir o resto.
ARTIGOS = {
    'pt-BR': r'o|a|os|as|um|uma|uns|umas',
    'pt': r'o|a|os|as|um|uma|uns|umas',
    'en': r'the|a|an',
    'es': r'el|la|los|las|un|una|unos|unas',
    'fr': r'le|la|les|un|une|des',
    'it': r'il|lo|la|i|gli|le|un|uno|una',
    'nl': r'de|het|een',
}


def sem_artigo(texto, lang):
    padrao = ARTIGOS.get(lang)
    if not padrao:
        return texto
    return ' / '.join(
        re.sub(rf'^({padrao})\s+', '', parte.strip(), flags=re.IGNORECASE) or parte.strip()
        for parte in texto.split(' / ')
    )


def validar(resposta, lote):
    """Rejeita o lote inteiro se vier torto. Meio lote é pior que nenhum."""
    esperadas = {f"{n['article']}|{n['word']}" for n in lote}
    if not isinstance(resposta, dict):
        raise ValueError('resposta não é um objeto JSON')

    faltando = esperadas - set(resposta)
    sobrando = set(resposta) - esperadas
    if faltando or sobrando:
        raise ValueError(f'chaves faltando: {sorted(faltando)[:3]}; sobrando: {sorted(sobrando)[:3]}')

    for chave, entrada in resposta.items():
        if not isinstance(entrada, dict) or set(entrada) != set(CAMPOS):
            raise ValueError(f'{chave}: campos {sorted(entrada) if isinstance(entrada, dict) else entrada}')
        texto = entrada['uebersetzung']
        if not isinstance(texto, str) or not texto.strip():
            raise ValueError(f'{chave}: tradução vazia')
        if not isinstance(entrada['mehrdeutig'], bool):
            raise ValueError(f'{chave}: mehrdeutig não é booleano')
        if len(texto.split(' / ')) > 3:
            raise ValueError(f'{chave}: mais de três sentidos — {texto!r}')
        if texto.rstrip().endswith(('.', ';', ',')):
            raise ValueError(f'{chave}: pontuação final — {texto!r}')
    return resposta


def fundir(resposta, traducoes, sinais, lang):
    for chave, entrada in resposta.items():
        traducoes[chave] = sem_artigo(entrada['uebersetzung'].strip(), lang)
        if entrada['mehrdeutig'] or entrada['verwechselbar_mit'].strip():
            sinais[chave] = {
                'mehrdeutig': entrada['mehrdeutig'],
                'verwechselbar_mit': entrada['verwechselbar_mit'].strip(),
            }


def dividir(faltando, tamanho, maximo):
    lotes = [faltando[i:i + tamanho] for i in range(0, len(faltando), tamanho)]
    return lotes[:maximo] if maximo else lotes


# --- modo subagente: emitir e ingerir ------------------------------------------

def emitir(lotes, lang, pasta):
    """Escreve um prompt por lote, para um agente por arquivo.

    O agente lê NNN.prompt.txt e escreve NNN.json ao lado. Nada mais precisa ser
    combinado: o nome do arquivo é o contrato.
    """
    pasta.mkdir(parents=True, exist_ok=True)
    for antigo in pasta.glob('*.prompt.txt'):
        antigo.unlink()
    for numero, lote in enumerate(lotes, 1):
        (pasta / f'{numero:03d}.prompt.txt').write_text(
            montar_prompt(lote, lang), encoding='utf-8'
        )
    chaves = {
        f'{numero:03d}': [f"{n['article']}|{n['word']}" for n in lote]
        for numero, lote in enumerate(lotes, 1)
    }
    (pasta / 'chaves.json').write_text(
        json.dumps(chaves, ensure_ascii=False, indent=2) + '\n', encoding='utf-8'
    )
    print(f'{len(lotes)} lotes em {pasta.relative_to(ROOT)}/')
    print(f'  cada agente: ler NNN.prompt.txt, escrever NNN.json ao lado')


def ingerir(base, lang, pasta):
    """Lê as respostas dos agentes, valida cada uma e funde o que passou."""
    indice = {f"{n['article']}|{n['word']}": n for n in base['nouns']}
    chaves = json.loads((pasta / 'chaves.json').read_text(encoding='utf-8'))
    traducoes, sinais = carregar_fonte(lang), carregar_sinais()

    aceitos = rejeitados = ausentes = 0
    for numero in sorted(chaves):
        arquivo = pasta / f'{numero}.json'
        if not arquivo.exists():
            ausentes += 1
            continue
        lote = [indice[c] for c in chaves[numero] if c in indice]
        try:
            dados = json.loads(arquivo.read_text(encoding='utf-8'))
            fundir(validar(dados, lote), traducoes, sinais, lang)
            aceitos += 1
        except (ValueError, json.JSONDecodeError) as erro:
            rejeitados += 1
            print(f'  lote {numero}: rejeitado — {erro}')

    gravar_fonte(lang, traducoes)
    gravar_sinais(sinais)
    print(f'\n{aceitos} lotes aceitos, {rejeitados} rejeitados, {ausentes} sem resposta')
    print(f'{len(traducoes)} traduções em tools/translations/{lang}.json')
    print(f'{len(sinais)} palavras com sinal em tools/signals.json')


# --- modo API -------------------------------------------------------------------

def chamar_modelo(prompt, modelo):
    try:
        import anthropic
    except ImportError:
        sys.exit('pacote `anthropic` não instalado:  python3 -m pip install anthropic')
    cliente = anthropic.Anthropic()
    resposta = cliente.messages.create(
        model=modelo, max_tokens=8000, temperature=0,
        messages=[{'role': 'user', 'content': prompt}],
    )
    texto = resposta.content[0].text.strip()
    if texto.startswith('```'):
        texto = texto.split('\n', 1)[1].rsplit('```', 1)[0]
    return json.loads(texto)


def via_api(lotes, lang, modelo, paralelo):
    traducoes, sinais = carregar_fonte(lang), carregar_sinais()
    trava = threading.Lock()
    feitos = 0

    def processar(item):
        numero, lote = item
        try:
            return numero, validar(chamar_modelo(montar_prompt(lote, lang), modelo), lote), None
        except Exception as erro:                       # noqa: BLE001 — rede e API
            return numero, None, erro

    with ThreadPoolExecutor(max_workers=paralelo) as executor:
        for futuro in as_completed([executor.submit(processar, i) for i in enumerate(lotes, 1)]):
            numero, resposta, erro = futuro.result()
            with trava:
                if erro is not None:
                    print(f'  lote {numero}: descartado — {erro}')
                    continue
                fundir(resposta, traducoes, sinais, lang)
                gravar_fonte(lang, traducoes)
                gravar_sinais(sinais)
                feitos += 1
                if feitos % 10 == 0 or feitos == len(lotes):
                    print(f'  {feitos}/{len(lotes)} lotes  ({len(traducoes)} traduções)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('lang', help='pt-BR, en, es, fr…')
    ap.add_argument('--lote', type=int, default=50)
    ap.add_argument('--max-lotes', type=int, default=0, help='0 = todos')
    ap.add_argument('--emitir', action='store_true', help='escreve os prompts para os agentes')
    ap.add_argument('--ingerir', action='store_true', help='lê as respostas dos agentes')
    ap.add_argument('--portao', action='store_true',
                    help='só as palavras com decisão humana; compara em vez de fundir')
    ap.add_argument('--api', action='store_true', help='gera pela API da Anthropic')
    ap.add_argument('--modelo', default=MODELO)
    ap.add_argument('--paralelo', type=int, default=6)
    ap.add_argument('--amostra', type=int, metavar='N', help='imprime o prompt e sai')
    args = ap.parse_args()

    base = carregar_base()
    # O portão escreve numa pasta própria: as respostas dele são medidas, nunca fundidas
    # na fonte. Misturá-las apagaria a decisão humana com o palpite do modelo.
    pasta = LOTES / (f'{args.lang}-portao' if args.portao else args.lang)

    if args.ingerir:
        if not pasta.exists():
            sys.exit(f'{pasta.relative_to(ROOT)} não existe — rode --emitir antes')
        if args.portao:
            return 0 if conferir_portao(base, args.lang, pasta) else 1
        return ingerir(base, args.lang, pasta) or 0

    fix = carregar_fix(args.lang)
    faltando = palavras_do_gabarito(base, args.lang) if args.portao else pendentes(base, args.lang)
    escopo = 'gabarito' if args.portao else 'a traduzir'
    print(f'{args.lang}: {base["count"]} palavras, {len(fix)} com correção humana, '
          f'{len(faltando)} {escopo}')

    if args.amostra:
        print('\n' + '=' * 70)
        print(montar_prompt(faltando[:args.amostra], args.lang))
        return 0
    if not faltando:
        print('Nada a fazer.')
        return 0

    lotes = dividir(faltando, args.lote, args.max_lotes)
    if args.emitir:
        emitir(lotes, args.lang, pasta)
    elif args.api:
        via_api(lotes, args.lang, args.modelo, args.paralelo)
    else:
        print('\nEscolha --emitir (subagentes), --api ou --amostra N')
    return 0


if __name__ == '__main__':
    sys.exit(main())
