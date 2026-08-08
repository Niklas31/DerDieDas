# Plataformas

Estado em 8 de agosto de 2026.

| Plataforma | Compila | Rodando | Capturas |
|---|---|---|---|
| iPhone | ✅ | ✅ simulador | ✅ 1320×2868 |
| iPad | ✅ | ✅ simulador | ✅ 2064×2752 |
| Apple Watch | ✅ | ✅ **relógio físico** | ✅ 416×496 |
| Apple Vision Pro | ✅ | ✅ simulador | ✅ 3840×2160 |
| Mac (Catalyst) | ✅ | ✅ abriu no Mac | ✅ 2560×1600 |
| Apple TV | ❌ | — | — |

## O que foi preciso mudar

O app era só de iPhone e iPad. Três APIs travavam o resto, todas isoladas por guarda
de plataforma em vez de virarem código duplicado:

**1. O framework Translation da Apple** não existe no visionOS nem no watchOS, e no Mac
Catalyst só a partir do macOS 26. Fica atrás de
`#if os(iOS) && !targetEnvironment(macCatalyst)` em `SearchView.swift`. Fora do iPhone e
do iPad, perde-se só a tradução de palavras **fora** da base — as 11.696 já vêm
traduzidas, então na prática ninguém sente falta.

**2. `tabViewSearchActivation`** (a aba de busca que vira campo de texto, do iOS 26) não
existe no visionOS. Guardado em `RootTabView.swift`; lá o TabView já é painel lateral e
não teria esse comportamento de qualquer forma.

**3. `Product.purchase()` não existe no visionOS.** Lá a folha de pagamento precisa ser
ancorada numa cena, senão o sistema não sabe em qual janela apresentá-la. Está em
`PurchaseStore.startPurchase(of:)`, que escolhe a variante certa por plataforma.

Além disso:

- O app do Watch embutido não pode acompanhar um binário visionOS — a fase
  "Embed Watch Content" e a dependência do target ganharam `platformFilters = (ios)`.
- No visionOS a janela nascia larga como uma TV, com o conteúdo perdido no meio de muito
  vazio. `ArtikelApp` define `.defaultSize(width: 720, height: 940)` só nessa plataforma,
  devolvendo o formato retrato que o app tem no iPhone e no iPad.
- O Mac Catalyst ganhou `Artikel/DerDieDas-Catalyst.entitlements` com **App Sandbox**,
  que a Mac App Store exige — sem isso o envio é recusado no upload. A rede está liberada
  só como cliente, para a App Store validar a compra do Pro.

## Capturas

`store/capturas/`, uma pasta por tamanho exigido:

| Pasta | Tamanho | Origem |
|---|---|---|
| `iphone-6.9/` | 1320×2868 | simulador do iPhone 17 Pro Max |
| `ipad-13/` | 2064×2752 | simulador do iPad Pro 13" (M5) |
| `visionos/` | 3840×2160 | simulador do Apple Vision Pro |
| `mac/` | 2560×1600 | app Catalyst no Mac |
| Apple Watch | 416×496 | Apple Watch Series 11 de 46 mm, aparelho físico |

As capturas do Watch vieram do relógio de verdade (botão lateral + coroa). Mantenha os
arquivos originais: qualquer app que recomprima muda o tamanho e o upload é recusado.

As do Mac vieram de capturas de janela (`⌘⇧4` + espaço), que saem no tamanho da janela —
1136×880 no caso. **A App Store só aceita 1280×800, 1440×900, 2560×1600 ou 2880×1800** e
recusa o envio fora disso, então elas foram ampliadas e centralizadas sobre o lilás da
marca até 2560×1600. Para refazer:

```bash
sips --resampleWidth 1700 entrada.png --out saida.png
sips --padToHeightWidth 1600 2560 --padColor D9CAFA saida.png --out saida.png
```

## Apple TV: não recomendo

Exigiria um target novo e uma interface nova — a tvOS trabalha com o *focus engine* e não
tem teclado de verdade. **Metade do app não sobrevive à tradução:** a busca, que é o uso
mais forte no dia a dia, vira digitar letra por letra com o controle remoto. O treino
Palavra → Artigo funcionaria bem (três botões grandes, quase feito para controle remoto),
mas seria publicar metade do app.

Se um dia quiser, o caminho é um target tvOS só com o treino, reusando `AppStore`,
`GermanNoun` e `ArticleBadge` — que já são compartilhados com o Watch e não têm nada de
específico de plataforma.

## Nota sobre o repositório

O projeto **saiu do iCloud Drive** e vive em `~/Developer/DerDieDas`. Projeto Xcode dentro
do iCloud é uma combinação ruim: o `.xcodeproj` é um pacote cujos arquivos internos
sincronizam separadamente (dá para subir um `project.pbxproj` pela metade), o build gera
sincronização constante, e o iCloud pode descarregar arquivos que o Xcode espera no disco.
