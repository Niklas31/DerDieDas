# DerDieDas

DerDieDas é um app para treinar os artigos (der/die/das) de substantivos em alemão, com tradução para o português e plural opcional.

Existe em duas versões, que compartilham a mesma base de dados:

- **Nativa** (SwiftUI) — projeto `DerDieDas.xcodeproj`. Compila para **iPhone, iPad,
  Apple Watch, Apple Vision Pro e Mac (Catalyst)**; ver `store/plataformas.md` para o
  que está verificado rodando e o que só compila.
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
- Na web: instalável na tela de início e funcionando offline (service worker).

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
cd docs && python3 -m http.server 8765
```

Sirva a partir de `docs/`, não da raiz do repositório: o escopo do service worker é a pasta
em que ele mora, e servir de fora colocaria o app numa subpasta diferente da de produção.

### Antes de todo push: `node tools/bump-sw.mjs`

O service worker (`docs/sw.js`) usa **cache-first** sobre uma lista fechada de arquivos, gravada
sob uma chave de cache versionada. É o que faz o app funcionar offline — e o que torna a versão
do cache crítica: publicar código novo sem trocá-la deixa quem já visitou o site preso na versão
antiga, sem conserto remoto.

Por isso a versão não se escreve à mão. `tools/bump-sw.mjs` regera a lista de arquivos e usa o
**hash do conteúdo de tudo em `docs/`** como versão — mudou um byte, muda a versão:

```bash
node tools/bump-sw.mjs
```

Quando uma versão nova é detectada, o app não troca sozinho (recarregar módulos no meio de um
treino perderia a resposta em andamento): mostra uma barra “Nova versão disponível”, e só ao
tocar em *Atualizar* o worker novo assume e a página recarrega.

**Uma base só, para os dois apps:** `docs/data/GermanNouns.json`. O Xcode empacota esse
mesmo arquivo (referência com `sourceTree = SOURCE_ROOT`) e a web faz `fetch` nele —
não existe etapa de geração nem artefato duplicado.

Ele não guarda `id`: a identidade de cada substantivo é `ARTIGO|palavra`, calculada em
`GermanNoun.id` no Swift e usada como chave no `localStorage` da web. Além de alinhar os dois
lados, isso encolhe o arquivo de 470 KB para 167 KB comprimidos — UUIDs são aleatórios e
não comprimem.

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

O resultado — **11.696 substantivos, todos com tradução** — vive em `docs/data/GermanNouns.json`. Cada item é identificado por `ARTIGO|palavra`, chave usada para persistir estatísticas, histórico e traduções sob demanda.

Busca, treino e artigos funcionam offline. A tradução nativa da Apple roda no dispositivo, pode pedir download de modelos na primeira vez e não funciona no simulador.

## Estrutura

```text
Artikel/               app iOS/watchOS (SwiftUI)
  ArtikelApp.swift
  PrivacyInfo.xcprivacy
  Models/
  Stores/              AppStore.swift, PurchaseStore.swift
  Views/               Search, History, Training, Statistics, Credits, Paywall
  Intents/
DerDieDas Watch App Watch App/
DerDieDas.storekit
DerDieDas.xcodeproj/
tools/
  corrections.json     correções sobre a tradução automática
  apply-corrections.py aplica-as na base
  bump-sw.mjs          regera lista e versão do cache do service worker
  make-web-icons.swift compõe os ícones do PWA a partir da arte do app iOS
docs/                  web app + GitHub Pages
  index.html           o app
  privacidade.html     política de privacidade
  sw.js                service worker (offline) — bloco GERADO, não editar à mão
  manifest.webmanifest
  js/ css/ icons/
  data/GermanNouns.json  A BASE — o app iOS empacota este mesmo arquivo
```

## Como abrir

Abra `DerDieDas.xcodeproj` no Xcode e rode o target `DerDieDas` em um simulador ou dispositivo físico. A tradução nativa exige iOS 18+ e deve ser testada em aparelho real.

### Limitação conhecida da base

A lista de origem foi deduplicada **por grafia**, e o alemão tem homônimos de gêneros
diferentes: `der Tag` (dia) e `das Tag` (o *tag* do inglês), `die Rolle` (papel) e
`der Rollen`, `die Steuer` (imposto) e `das Steuer` (volante). Quando dois sentidos
colidiam, sobrava um registro só — às vezes com o artigo de um, o plural de outro e a
tradução de um terceiro.

A auditoria em `tools/` usa os **compostos como votação**: em alemão o composto herda o
artigo do último elemento, então 27 compostos em `-tag` marcados DER provam que `Tag` é
DER. Foi assim que apareceram `Fall`, `Ort`, `Bereich`, `Bruch`, `Rolle`, `Wende`,
`Steuer`, `Kiefer`, `Bauer` e `Moment` com artigo errado — num app que ensina artigos,
o pior defeito possível.

**Não foi uma varredura completa.** O método só enxerga palavras que aparecem como núcleo
de compostos, e o teste exige pelo menos quatro compostos concordando. Palavras isoladas
passam batido. A correção de raiz é regerar a base do `german-nouns` usando
`(artigo, palavra)` como chave em vez de só a palavra — aí nenhum sentido é engolido.
Até lá, os reportes que chegam pelo botão do app cobrem o resto.
