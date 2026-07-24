# DerDieDas

DerDieDas é um app SwiftUI (iOS e watchOS) para treinar os artigos (der/die/das) de substantivos em alemão, com tradução para o português e plural opcional.

## Funcionalidades

- Buscar substantivos por palavra, artigo, tradução ou plural (offline, sem acentuação obrigatória).
- Ver artigo em destaque, palavra, tradução e plural, com opção de ocultar a tradução.
- Histórico de buscas com tempo relativo.
- Treino em dois modos: Palavra → Artigo e Artigo → Palavra.
- Estatísticas de palavras mais erradas, artigos com maior índice de erro e última prática.
- Tradução sob demanda de palavras fora da base, via Translation framework da Apple (iOS 18+, no dispositivo).
- App companheiro para Apple Watch.
- App Intents / Atalhos da Siri para consultar o artigo de uma palavra.

## Modelo (freemium)

- Plano gratuito: **10 palavras novas por dia** (rever uma palavra já vista no dia não conta; reseta à meia-noite).
- **DerDieDas Pro**: compra única (não-consumível, StoreKit 2) que remove o limite. Produto `com.nicolas.DerDieDas.pro`.
- Teste local via `DerDieDas.storekit` (já referenciado no scheme).

## Base de dados

A base parte do projeto aberto [`gambolputty/german-nouns`](https://github.com/gambolputty/german-nouns), compilado do Wikcionário alemão (WiktionaryDE) e publicado sob **CC BY-SA 4.0** — mais de 90 mil substantivos com artigo e plural.

Essa lista foi curada num script em Python (Google Colab):

1. Filtros de regex removem química complexa, moedas antigas, símbolos, abreviações e verbos.
2. Filtro de frequência com a biblioteca `wordfreq`, corte `1e-6` (0,0001% — ~1 ocorrência por milhão), descartando a cauda longa de termos raros.
3. Tradução para o português com o Google Tradutor (`deep_translator`).

O resultado — **12.092 substantivos, todos com tradução** — é empacotado em `Artikel/GermanNouns.json`. Cada item tem um `id` (UUID estável), usado para persistir traduções sob demanda e estatísticas.

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
docs/index.html      Política de privacidade (GitHub Pages)
DerDieDas.xcodeproj/
```

## Como abrir

Abra `DerDieDas.xcodeproj` no Xcode e rode o target `DerDieDas` em um simulador ou dispositivo físico. A tradução nativa exige iOS 18+ e deve ser testada em aparelho real.
