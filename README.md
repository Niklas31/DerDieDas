# Artikel

Artikel é um app SwiftUI para aprender substantivos alemães com artigo, tradução para português e plural opcional.

## Funcionalidades

- Buscar substantivos por palavra, artigo, tradução ou plural.
- Ver artigo em destaque, palavra, tradução e plural.
- Traduzir palavras sem tradução curada usando a tradução nativa da Apple em dispositivos com iOS 18 ou superior.
- Ocultar ou mostrar a tradução na busca.
- Histórico de buscas com tempo relativo.
- Treino em dois modos:
  - Palavra -> Artigo
  - Artigo -> Palavra
- Configuração para mostrar ou ocultar tradução durante o treino.
- Estatísticas de palavras mais erradas, artigos com maior índice de erro e última prática.

## Base de dados

O app carrega os substantivos de `Artikel/GermanNouns.json`, empacotado como recurso do app. A base atual tem 91.836 substantivos alemães com artigo e plural opcional. A lista inclui 100 traduções em português curadas; as demais podem ser traduzidas sob demanda no app e ficam salvas localmente no aparelho.

Os campos de artigo e plural foram estruturados com apoio do projeto aberto `gambolputty/german-nouns`, compilado do WiktionaryDE e publicado sob CC BY-SA 4.0. As traduções em português da lista inicial foram curadas para o app; traduções geradas no aparelho usam o Translation framework da Apple.

Artigo, plural, busca e treino funcionam offline porque a base está dentro do app. A tradução nativa da Apple também roda no dispositivo, mas pode pedir download dos modelos de idioma na primeira utilização e não funciona no simulador iOS.

## Estrutura

```text
Artikel/
  GermanNouns.json
  Models/
  Stores/
  Views/
  ArtikelApp.swift
Artikel.xcodeproj/
prompt.md
```

## Como abrir

Abra `Artikel.xcodeproj` no Xcode e rode o target `Artikel` em um simulador iOS ou dispositivo físico. A tradução nativa exige iOS 18 ou superior e deve ser testada em um dispositivo físico.
