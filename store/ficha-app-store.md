# Ficha da App Store — DerDieDas

Material pronto para colar no App Store Connect. Idioma principal: **Português (Brasil)**.
Os limites de caracteres da Apple estão anotados em cada campo; rode
`python3 store/checar-limites.py` depois de qualquer edição.

---

## Nome do app  · limite 30

```
DerDieDas: Artigos Alemães
```

Alternativa, se preferir sem descritor: `DerDieDas`.

O descritor ajuda a ser encontrado — há mais de dez apps chamados "Der Die Das" na
loja, e o nome é o campo de maior peso na busca da App Store. Ver `nome-e-marca.md`.

## Subtítulo  · limite 30

```
Dicionário e treino diário
```

## Palavras-chave  · limite 100, separadas por vírgula, sem espaços

```
alemao,deutsch,artigo,substantivo,vocabulario,gramatica,flashcard,traducao,plural,a1,b1,ingles
```

Não repita palavras que já estão no nome ou no subtítulo — a Apple indexa os três campos
juntos, e repetir desperdiça caracteres.

## Texto promocional  · limite 170 · editável sem nova versão

```
11.694 substantivos alemães com artigo, tradução e plural. Busca instantânea, treino nos dois sentidos e estatísticas dos erros. Offline, sem conta e sem anúncios.
```

## Descrição  · limite 4000

```
Decorar se cada substantivo alemão é der, die ou das é o obstáculo que quase todo brasileiro encontra ao aprender o idioma. Não existe atalho fácil — e foi para atacar exatamente essa dificuldade que o DerDieDas nasceu.

UMA BASE CURADA, NÃO UM DICIONÁRIO GIGANTE
São 11.694 substantivos realmente úteis do cotidiano, cada um com artigo, tradução e plural. A lista partiu de mais de 90 mil palavras do Wikcionário alemão e passou por um filtro de frequência de uso: só ficaram as que aparecem pelo menos cerca de uma vez por milhão no alemão real. Isso derruba a cauda longa de termos químicos, moedas antigas e palavras que ninguém usa.

TRADUÇÃO EM PORTUGUÊS OU EM INGLÊS
Escolha o idioma da tradução na aba Treino, ou deixe no automático e o app segue o idioma do seu iPhone. Útil para quem já estuda alemão a partir do inglês e prefere não passar pelo português no meio do caminho.

BUSCA INSTANTÂNEA
Digite em alemão ou em português. A busca ignora acentos e maiúsculas — procurar "strasse" encontra "Straße", "grun" encontra "grün". Também funciona por plural e por artigo, se você quiser ver só as palavras que usam das.

DOIS MODOS DE TREINO
• Palavra → Artigo: aparece o substantivo, você escolhe der, die ou das.
• Artigo → Palavra: aparece o artigo, você escreve uma palavra que o use.
Com a opção de mostrar ou esconder a tradução durante a prática.

ESTATÍSTICAS QUE MOSTRAM ONDE VOCÊ ERRA
As palavras que mais escapam, os artigos com maior índice de erro e quando você praticou cada uma pela última vez. Treinando o vocabulário certo, os padrões escondidos da língua começam a aparecer sozinhos: palavras terminadas em -ung são sempre die, as em -chen são das, infinitivos substantivados são das.

FUNCIONA OFFLINE, DE VERDADE
A base inteira fica no aparelho. Sem internet, sem conta, sem login, sem anúncios e sem rastreadores. Nada do que você faz sai do seu iPhone.

TAMBÉM NO APPLE WATCH E NA SIRI
Consulte o artigo de uma palavra pelo relógio ou pergunte à Siri, sem tirar o telefone do bolso.

PLANO GRATUITO E DERDIEDAS PRO
O plano gratuito libera 10 palavras novas por dia — rever uma palavra que você já viu hoje não conta, e o limite reinicia à meia-noite. O DerDieDas Pro é uma compra única, sem assinatura e sem mensalidade, que remove o limite para sempre.

CRÉDITOS
A base de artigos e plurais vem do projeto aberto german-nouns, compilado do Wikcionário alemão e publicado sob licença Creative Commons Atribuição-CompartilhaIgual 4.0 (CC BY-SA 4.0). Encontrou uma tradução errada? Há um botão para reportar em cada palavra — as correções entram nas próximas versões.
```

## Novidades desta versão  · limite 4000 · primeira versão

```
Primeira versão do DerDieDas.
```

## URLs

| Campo | Valor |
|---|---|
| URL de marketing | `https://derdiedas.app.br` |
| URL de suporte | `https://derdiedas.app.br` |
| Política de privacidade | `https://derdiedas.app.br/privacidade.html` |

## Categoria e classificação

| Campo | Valor |
|---|---|
| Categoria principal | Educação |
| Categoria secundária | Referência |
| Classificação etária | **4+** — ver `classificacao-etaria.md` |
| Direitos autorais | `2026 Nicolas Lehmann` |

---

## Compra no app

| Campo | Valor |
|---|---|
| Nome de referência | DerDieDas Pro |
| ID do produto | `com.nicolas.DerDieDas.pro` |
| Tipo | Não-consumível |
| Preço | R$ 9,90 |
| Nome de exibição | DerDieDas Pro |
| Descrição | Acesso vitalício: palavras ilimitadas na busca e no treino, sem limite diário. |

O `DerDieDas.storekit` do projeto serve só para teste local. Este produto precisa ser
criado no App Store Connect com **exatamente** o mesmo ID, senão a tela de compra
aparece vazia em produção.

A compra exige uma captura de tela de revisão: use a tela do paywall
(Treino → ⓘ → "Desbloquear palavras ilimitadas"). Ela precisa mostrar o preço formatado —
se aparecer "Carregando…" no botão, o produto não carregou e a captura não serve.

A captura pronta está em `store/capturas/iap/paywall-1284x2778.png`.

**Este campo NÃO usa a lista de tamanhos da vitrine.** É a armadilha central: 1320 × 2868 é
o tamanho obrigatório das capturas de 6,9" do app e é **recusado aqui**. A captura de
revisão da compra aceita a lista antiga — no iPhone, 1242 × 2688 ou 1284 × 2778. Por isso
`store/capturas/iphone-6.9/` não serve para este campo e existe `store/capturas/iap/`.

E a mensagem de erro engana: ela diz "The dimensions of one or more screenshots are wrong"
para qualquer recusa, inclusive quando a dimensão está certa. Uma captura vinda do iPhone
chega com três problemas invisíveis, e nenhum deles é o tamanho:

| o que vem do iPhone | por que atrapalha |
|---|---|
| canal alfa (se você redimensionou no Preview) | a Apple exige imagem achatada |
| perfil Display P3 + chunk `cICP` | sinalização de gama larga/HDR que o validador não espera |
| chunk `eXIf` | guarda as dimensões originais, que não batem com as novas |

`tools/preparar-captura-iap.sh` faz os três consertos e o redimensionamento. Confira o
resultado com:

```
sips -g pixelWidth -g pixelHeight -g hasAlpha -g bitsPerSample -g profile arquivo.png
```

Precisa dar `hasAlpha: no`, `bitsPerSample: 8` e perfil sRGB.

---

## Notas para a equipe de revisão

Em inglês de propósito: o revisor lê dezenas por dia, e a Apple respondeu em inglês. Este
texto responde aos oito itens do pedido 2.1 da primeira revisão — **antes** de reenviar,
preencha a lista de aparelhos testados, que é a única parte que só você sabe.

```
NO ACCOUNT, NO LOGIN, NO SERVER
The app works entirely offline. There is no account, no login, no sign-up, and no user data
of any kind. Nothing is transmitted anywhere. No demo credentials are needed or possible.

1. WHAT THE APP DOES AND WHO IT IS FOR
German nouns each carry one of three grammatical genders, marked by the articles der, die
or das. The article is not predictable from the word and must be memorized. This is the
single biggest obstacle for Brazilian and other non-native learners of German, and it is
what this app addresses.

The app bundles 11,694 curated German nouns, each with its article, its plural and a
translation. The user can search any noun, practice in two directions, and see statistics
of the words they get wrong most often. Target audience: people learning German at the A1
to B1 levels.

2. DEVICES AND OPERATING SYSTEMS TESTED
[PREENCHER ANTES DE ENVIAR — liste apenas o que você realmente testou, por exemplo:
"iPhone 17 Pro, iOS 27.0" / "iPad Air 11-inch (M3), iPadOS 27.0" / "Apple Watch Series 10,
watchOS 11". Não invente aparelhos: se algo não foi testado, não liste.]

3. HOW TO SET UP AND REACH THE MAIN FEATURES
No setup at all. Install and open.
- Search tab: type a German or Portuguese word. Try "Hund". Accents and case are ignored,
  so "strasse" finds "Straße".
- Training tab: two modes. "Palavra -> Artigo" shows a noun, you pick der/die/das.
  "Artigo -> Palavra" shows an article, you type any noun that uses it.
- Training tab -> "Idioma da tradução": switches translations between Portuguese and
  English, or follows the device language when set to "Automático".
- History tab: words you looked up before.

4. IN-APP PURCHASE — WHAT IT BUYS AND HOW TO REACH IT
There is exactly one purchase: "DerDieDas Pro" (com.nicolas.DerDieDas.pro), a
non-consumable one-time purchase. There are no subscriptions.

The free plan allows 10 NEW words per day, across search and training combined. Re-opening
a word already seen today does not count. The counter resets at midnight. The purchase
removes this daily limit permanently. Nothing else is gated: the full 11,694-word database,
both translation languages, all statistics and the Apple Watch app are available for free.

Shortest path to the purchase screen:
  Training tab -> (i) button, top right -> "Desbloquear palavras ilimitadas"
The purchase screen shows the price and a "Restaurar Compras" (Restore Purchases) button.

The same screen also appears on its own once the daily limit is reached: answer 10 different
words in the Training tab.

5. EXTERNAL SERVICES, TOOLS AND PLATFORMS
At runtime the app calls no external service whatsoever. Specifically: no servers of ours,
no analytics, no advertising, no third-party SDKs, no trackers, and no AI service.

Two Apple frameworks are used:
- StoreKit 2, for the single in-app purchase.
- Translation (Apple's on-device translation), used only for words the user searches that
  are NOT in the bundled database. All 11,694 bundled words already ship translated, so
  this is a rare fallback. It runs on the device and may ask to download a language model
  the first time. It does not work in the Simulator.

The noun database is a static JSON file compiled into the app at build time. The word list,
the translations and the review of them were all produced offline during development; no
generation happens on the user's device or at runtime.

6. REGIONAL DIFFERENCES
None. The app behaves identically in every region and every country. There is no
geo-restricted content, no regional pricing logic in the app, and no feature that varies by
location. The app never requests location.

The only thing that varies is the translation language shown next to each German word,
which follows the device language (Portuguese or English) and can be changed by the user in
the Training tab. The German content — article, word, plural — is the same everywhere.

7. THIRD-PARTY MATERIAL AND AUTHORIZATION
The articles and plurals derive from "german-nouns", an open dataset compiled from the
German Wiktionary and published under Creative Commons Attribution-ShareAlike 4.0
(CC BY-SA 4.0), which permits redistribution with attribution. Attribution is given inside
the app at Training tab -> (i) -> "Créditos & Licenças", with links to the project, to the
German Wiktionary and to the license text, and it is also stated in the App Store
description. The app is not part of any regulated industry.

8. PRIVACY
Search history and practice statistics are stored only on the device, in the app's own
storage. They are never transmitted and are removed when the app is deleted. This matches
the "Data Not Collected" declaration and the privacy policy at
https://derdiedas.app.br/privacidade.html
```

### Roteiro da gravação de tela

A Apple pede um vídeo feito em **aparelho físico**, começando pela abertura do app. A
revisão anterior rodou num **iPad Air 11-inch (M3)** — se você tiver um iPad, grave nele,
porque é o aparelho em que eles já olharam.

1. Abrir o app a partir da tela de início (o vídeo precisa começar aqui)
2. Aba Buscar → digitar `Hund` → tocar no resultado → mostrar o cartão com artigo,
   tradução e plural
3. Aba Treino → responder duas ou três palavras, uma delas errada, para mostrar o retorno
4. Trocar "Idioma da tradução" para English e mostrar a mesma palavra em inglês
5. Ligar "Mostrar tradução durante o treino"
6. Rolar até as Estatísticas Extras
7. Aba Histórico
8. Treino → ⓘ → mostrar Créditos & Licenças (a atribuição CC BY-SA)
9. Voltar e tocar em "Desbloquear palavras ilimitadas" → **a tela de compra com o preço
   visível** → tocar em Desbloquear e mostrar a folha de pagamento da Apple

O passo 9 é o mais importante: foi a compra que eles não conseguiram avaliar.

---

## Capturas de tela

Geradas em `store/capturas/iphone-6.9/`, no iPhone 17 Pro Max — **1320 × 2868**, que é o
tamanho obrigatório de 6,9". Ordem sugerida:

1. `01-buscar.png` — busca por "Hund", com correspondência exata e resultados relacionados
2. `02-card.png` — a palavra em destaque, com artigo, tradução, plural e o histórico
3. `03-treino.png` — treino Palavra → Artigo, com os três botões
4. `04-estatisticas.png` — palavras mais erradas, índice de erro por artigo e última prática

Como o app mantém suporte a iPad, há também `store/capturas/ipad-13/` — **2064 × 2752**,
o tamanho obrigatório de iPad 13".

Se publicar o app do Apple Watch junto, ele exige as próprias capturas.
