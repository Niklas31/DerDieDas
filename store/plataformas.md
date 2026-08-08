# Plataformas

Estado em 8 de agosto de 2026.

| Plataforma | Compila | Verificado rodando | Capturas | Observação |
|---|---|---|---|---|
| iPhone | ✅ | ✅ simulador | ✅ 1320×2868 | — |
| iPad | ✅ | ✅ simulador | ✅ 2064×2752 | — |
| Apple Watch | ✅ | ❌ | ❌ | falta o runtime de simulador |
| Apple Vision Pro | ✅ | ❌ | ❌ | falta o runtime de simulador |
| Mac (Catalyst) | ✅ | ✅ abriu no Mac | ❌ | não consegui capturar a tela |
| Apple TV | ❌ | — | — | exigiria outro target e outra interface |

## O que foi preciso mudar

O app era só de iPhone/iPad. Três coisas travavam as outras plataformas:

**1. O framework Translation da Apple** não existe no visionOS nem no watchOS, e no
Mac Catalyst só a partir do macOS 26. Ele agora está atrás de
`#if os(iOS) && !targetEnvironment(macCatalyst)` em `SearchView.swift`. Fora do
iPhone e do iPad, o app perde só a tradução de palavras **fora** da base — as
11.695 da base já vêm traduzidas, então na prática ninguém sente falta.

**2. `tabViewSearchActivation`** (a aba de busca que vira campo de texto, do iOS 26)
não existe no visionOS. Guardado em `RootTabView.swift`; lá o TabView já é um painel
lateral e não teria esse comportamento de qualquer forma.

**3. `Product.purchase()` não existe no visionOS.** Lá a folha de pagamento precisa
ser ancorada numa cena, senão o sistema não sabe em qual janela apresentá-la. Está em
`PurchaseStore.startPurchase(of:)`, que escolhe a variante certa por plataforma.

Além disso, o app do Watch embutido não pode acompanhar um binário visionOS — a fase
"Embed Watch Content" e a dependência do target ganharam `platformFilters = (ios)`.

## O que falta, e por quê

### Apple Watch e Vision Pro: falta espaço em disco

Os SDKs estão instalados e **os dois compilam**, mas os *runtimes de simulador* não
foram baixados — só o do iOS 27 está presente. Sem eles não dá para rodar nem capturar
tela.

O problema é espaço: **restam 13 GB livres**. O runtime do watchOS pesa cerca de 7 GB e
o do visionOS cerca de 10 GB; os dois juntos não cabem.

```bash
xcodebuild -downloadPlatform watchOS
```

```bash
xcodebuild -downloadPlatform visionOS
```

**Atalho para o Watch:** você tem um Apple Watch de verdade pareado (apareceu como
"Apple Watch de Nicolas" ao listar destinos). A Apple aceita capturas tiradas do
aparelho físico — botão lateral + coroa digital ao mesmo tempo, e a imagem vai para as
Fotos do iPhone. É mais rápido que baixar 7 GB, e mostra o app rodando de verdade.

### Mac: compila e abre, mas não consegui ver

O build de Mac Catalyst funciona e o app **abriu no seu Mac**. Não consegui capturar a
janela nem inspecioná-la: `screencapture` exige permissão de Gravação de Tela e o
AppleScript exige Automação — ajustes de sistema que não vou mexer. Abra o app e julgue
você mesmo antes de decidir publicar essa versão.

Vale saber que **existe um caminho sem trabalho nenhum**: no App Store Connect há uma
opção de disponibilizar o app de iPad em Macs com Apple Silicon ("Designed for iPad").
É uma caixa de seleção, não exige build separado, não exige capturas de Mac e não passa
por revisão adicional. Se a janela do Catalyst não te convencer, essa é a saída barata.

Publicar Catalyst exige capturas próprias de Mac (1280×800 ou 2560×1600).

### Apple TV: não recomendo agora

Exigiria um target novo e uma interface nova — a tvOS trabalha com o *focus engine* e
não tem teclado de verdade. **Metade do app não sobrevive à tradução:** a busca, que é
o uso mais forte no dia a dia, vira digitar letra por letra com o controle remoto. O
treino Palavra → Artigo funcionaria bem (três botões grandes, é quase feito para
controle remoto), mas seria publicar metade do app.

Se um dia quiser, o caminho é um target tvOS só com o treino, reusando `AppStore`,
`GermanNoun` e `ArticleBadge` — que já são compartilhados com o Watch e não têm nada
de específico de plataforma.
