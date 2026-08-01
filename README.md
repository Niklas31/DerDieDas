# DerDieDas

DerDieDas é um app para treinar os artigos (der/die/das) de substantivos em alemão, com tradução para o português e plural opcional.

Existe em duas versões, que compartilham a mesma base de dados:

- **Nativa** (SwiftUI, iOS e watchOS) — projeto `DerDieDas.xcodeproj`.
- **Web** (PWA estático) — pasta `docs/`, publicada no GitHub Pages em <https://derdiedas.app.br>.

## Funcionalidades

- Buscar substantivos por palavra, artigo, tradução ou plural (offline, sem acentuação obrigatória).
- Ver artigo em destaque, palavra, tradução e plural, com opção de ocultar a tradução.
- Histórico de buscas com tempo relativo.
- Treino em dois modos: Palavra → Artigo e Artigo → Palavra.
- Estatísticas de palavras mais erradas, artigos com maior índice de erro e última prática.
- Tradução sob demanda de palavras fora da base, via Translation framework da Apple (iOS 18+, no dispositivo).
- App companheiro para Apple Watch.
- App Intents / Atalhos da Siri para consultar o artigo de uma palavra.

## Modelo

App nativo (freemium):

- Plano gratuito: **10 palavras novas por dia** (rever uma palavra já vista no dia não conta; reseta à meia-noite).
- **DerDieDas Pro**: compra única (não-consumível, StoreKit 2) que remove o limite. Produto `com.nicolas.DerDieDas.pro`.
- Teste local via `DerDieDas.storekit` (já referenciado no scheme).

Versão web: **gratuita e ilimitada**. Num site estático qualquer limite viveria no `localStorage` e seria
contornável pelo devtools, então não há paywall — `FREE_LIMIT` em `docs/js/store.js` fica em `Infinity`.

## Web app (`docs/`)

PWA estático, sem backend, sem build step: HTML + CSS + JavaScript com ES modules nativos.
`git push` publica.

```bash
node tools/build-web-data.mjs   # regenera docs/data/nouns.v1.json a partir do JSON do app
python3 -m http.server 8765     # e abrir http://localhost:8765/docs/
```

`Artikel/GermanNouns.json` é a fonte única de verdade; `docs/data/nouns.v1.json` é um artefato
**gerado** (linhas em vez de objetos, sem o campo `id`): 2,1 MB → 486 KB, ~144 KB via gzip.

Limitação conhecida: no iOS o WebKit só abre o teclado dentro de um gesto do usuário, então a versão
web não abre o teclado sozinha ao iniciar (o app nativo abre). Para compensar, o campo de resposta do
treino é um nó de DOM permanente — o teclado não fecha entre uma palavra e outra.

## Base de dados

A base parte do projeto aberto [`gambolputty/german-nouns`](https://github.com/gambolputty/german-nouns), compilado do Wikcionário alemão (WiktionaryDE) e publicado sob **CC BY-SA 4.0** — mais de 90 mil substantivos com artigo e plural.

Essa lista foi curada num script em Python (Google Colab):

1. Filtros de regex removem química complexa, moedas antigas, símbolos, abreviações e verbos.
2. Filtro de frequência com a biblioteca `wordfreq`, corte `1e-6` (0,0001% — ~1 ocorrência por milhão), descartando a cauda longa de termos raros.
3. Tradução para o português com o Google Tradutor (`deep_translator`).

4. Revisão manual sobre o resultado da tradução automática, versionada em `tools/corrections.json`
   e aplicada por `tools/apply-corrections.py`: corrige traduções erradas e remove nomes próprios,
   marcas e siglas. Os reportes que chegam pelo botão do app entram nesse mesmo arquivo.

O resultado — **11.729 substantivos, todos com tradução** — é empacotado em `Artikel/GermanNouns.json`. Cada item tem um `id` (UUID estável), usado para persistir traduções sob demanda e estatísticas.

Busca, treino e artigos funcionam offline. A tradução nativa da Apple roda no dispositivo, pode pedir download de modelos na primeira vez e não funciona no simulador.

## Estrutura

```text
Artikel/
  ArtikelApp.swift
  GermanNouns.json
  PrivacyInfo.xcprivacy
  Models/
  Stores/            AppStore.swift, PurchaseStore.swift
  Views/             Search, History, Training, Statistics, Credits, Paywall
  Intents/
DerDieDas Watch App Watch App/
DerDieDas.storekit
DerDieDas.xcodeproj/
tools/build-web-data.mjs
docs/                Web app + GitHub Pages
  index.html         o app
  privacidade.html   política de privacidade
  js/ css/ icons/
  data/nouns.v1.json GERADO — não editar à mão
```

## Como abrir

Abra `DerDieDas.xcodeproj` no Xcode e rode o target `DerDieDas` em um simulador ou dispositivo físico. A tradução nativa exige iOS 18+ e deve ser testada em aparelho real.
