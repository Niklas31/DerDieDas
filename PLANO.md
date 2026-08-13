# DerDieDas — plano da 1.1 e da 2.0

Escrito depois da submissão da 1.0 (iOS + Apple Watch dependente, português e inglês).

---

## 1.1 — quatro plataformas

Alvos: **Watch independente**, **macOS**, **visionOS** e **tvOS** (só o treino, limite de 20
palavras e compra).

### O tema real da 1.1 não é "quatro plataformas"

É **o que a compra significa fora do iPhone**. As quatro levantam a mesma pergunta, e ela
não tem resposta hoje:

| plataforma | por que a compra vira problema |
|---|---|
| Watch independente | dá para instalar sem o iPhone, e não existe caminho para comprar nem restaurar |
| tvOS | tem limite de 20, logo **precisa** de compra na própria TV |
| macOS / visionOS | a `PaywallView` é uma tela de iPhone; nas duas ela precisa existir em outra forma |

A parte fácil já está resolvida: `refreshEntitlements` lê `Transaction.currentEntitlements`,
que a Apple sincroniza pelo Apple ID. Quem comprar em qualquer lugar destrava em todos.
O que falta é o **caminho de compra** em cada tela.

Já a contagem do plano gratuito **não** sincroniza: `viewedTodayIDs` mora no `UserDefaults`
de cada aparelho. Na prática, a pessoa ganha 10 no iPhone mais 20 na TV mais o que o relógio
decidir, todos independentes. Isso é uma decisão de produto, não um bug — mas precisa ser
decidida de propósito, e não descoberta depois.

### Pré-requisitos, antes de escrever qualquer tela nova

**1. Extrair as strings (tarefa #5, ainda pendente).** São ~133 strings em Swift e ~95 na
web, todas em português cravado no código. Cada tela nova escrita antes da extração é mais
uma para caçar depois — e a 1.1 vai escrever muitas telas. Esta é a única tarefa que fica
mais cara a cada dia de atraso.

**2. `dailyFreeLimit` deixa de ser constante.** Hoje:

```swift
let dailyFreeLimit = 10        // AppStore.swift:37
```

Com a TV em 20, isso vira um valor por plataforma. Fazer isso *antes* do alvo tvOS existir
custa cinco minutos; fazer depois significa mexer em código que já tem três plataformas
dependendo dele.

**3. Separar o texto da paywall da forma da paywall.** Hoje `PaywallView` mistura as duas
coisas. Com quatro plataformas, ou o texto vive num lugar só, ou você vai ter quatro cópias
divergindo — e a que diverge silenciosamente é a que ninguém abre.

**4. Decidir Mac Catalyst ou macOS nativo.** O projeto declara os dois hoje
(`SUPPORTS_MACCATALYST = YES` **e** `macosx` em `SUPPORTED_PLATFORMS`). Catalyst é mais
barato e reaproveita a interface do iPad; nativo dá um app melhor e mais trabalho. Decidir
antes de escrever interface específica de macOS, senão o trabalho é jogado fora.

### macOS

O build no Xcode Cloud falhou com cinco erros que são **dois**:

| linha | causa real |
|---|---|
| `TrainingView.swift:121` | `.topBarTrailing` não existe no macOS |
| `TrainingView.swift:191` | `.textInputAutocapitalization` não existe no macOS |

Os erros de `roundedBorder`, `never` e `done` (linhas 191–194) são cascata: quando o
modificador da 191 falha, o Swift perde a inferência da cadeia inteira. Consertar a 191
apaga três erros.

Também perde a tradução sob demanda: `SearchView` já guarda o `Translation` atrás de
`#if os(iOS) && !targetEnvironment(macCatalyst)`, e no Catalyst o framework só existe a
partir do macOS 26.

### visionOS

**Já compila** — passou verde no Xcode Cloud sem nenhuma mudança. O trabalho é de teste e
de loja, não de código: capturas em 3840 × 2160 e conferir que os painéis não ficam
estranhos. `PurchaseStore` já tem uma guarda `#if os(visionOS)` na compra.

Perde a tradução sob demanda, pelo mesmo motivo do Catalyst.

### tvOS — o maior trabalho da versão

Alvo novo, não está em `SUPPORTED_PLATFORMS` hoje.

**Só um dos dois modos de treino funciona.** `articleToWord` pede que a pessoa *digite* um
substantivo alemão — no controle da Apple TV isso é uma catraca de letras, insuportável.
Já `wordToArticle` é quase desenhado para a TV: três botões grandes, DER/DIE/DAS, que o
direcional percorre naturalmente. **A versão de TV deve ter só `wordToArticle`**, e isso não
é uma limitação a lamentar, é a forma certa naquele aparelho.

Consequência boa: sem digitação, sem busca — o que já bate com "apenas o treino".

O resto do custo é de plataforma, não de lógica:

- **Ícone em camadas** (efeito parallax), que é um conjunto de imagens próprio
- **Motor de foco**: cada botão precisa de estado de foco explícito, senão o controle
  não sabe para onde ir
- **Paywall navegável por foco**, já que a compra acontece na própria TV
- **Capturas** em 1920 × 1080 ou 3840 × 2160

### Watch independente

Uma chave liga:

```
INFOPLIST_KEY_WKRunsIndependently = YES
```

O dado já está pronto — o alvo do relógio embala `GermanNouns.json` e a pasta `lang` nos
próprios recursos, então ele nunca dependeu do telefone para conteúdo. Só estava
*declarado* dependente.

O que falta é tudo em volta:

- Hoje o relógio **não tem uma linha** sobre compra: nenhuma referência a `PurchaseStore`,
  `isPro`, `registerFreeView` ou limite. Coerente enquanto quem tem relógio tem iPhone.
- Independente, alguém pode instalar só o relógio — e aí não há como comprar nem restaurar.
  É o beco sem saída que a revisão da Apple costuma reprovar.
- **Decisão pendente:** o relógio passa a ter limite? Sem limite, ele entrega busca
  ilimitada de graça e mina o Pro do iPhone. Com limite, precisa de paywall na tela pequena.
- Capturas próprias, nos tamanhos de Apple Watch.

### Ordem sugerida

1. Extrair as strings
2. `dailyFreeLimit` por plataforma + separar o texto da paywall
3. Consertar os dois erros de macOS
4. macOS e visionOS (baratos: um quase compila, o outro já compila)
5. tvOS
6. Watch independente

Os itens 3–6 são independentes entre si. Os itens 1 e 2 bloqueiam todos.

---

## 2.0 — frase de exemplo com Foundation Models

Ideia: para cada palavra, uma frase de exemplo **sempre diferente**, gerada pelo modelo da
Apple no próprio aparelho, com a tradução vindo do SDK de tradução.

### O risco central, e ele é grande

**Um modelo de linguagem vai errar o artigo às vezes.** Num app cujo único propósito é
ensinar artigos, uma frase gerada com *"die Rock"* não é um defeito menor — ensina
exatamente o contrário do que o app existe para ensinar. É pior do que não ter a função.

### A defesa, e ela é sólida

**O app já sabe a resposta certa.** Toda frase gerada pode ser conferida mecanicamente antes
de aparecer na tela: achar o substantivo na frase e verificar se o artigo que o antecede
concorda com o artigo conhecido.

O alemão declina, então a checagem é por conjunto, não por igualdade:

| gênero | formas aceitas antes do substantivo |
|---|---|
| DER | der, den, dem, des · ein, einen, einem, eines |
| DIE | die, der · eine, einer |
| DAS | das, dem, des · ein, einem, eines |

Os conjuntos se sobrepõem de propósito — *der* é masculino nominativo **e** feminino
genitivo/dativo, e é por isso que "der Frau" é correto. Mas o erro que importa é justamente
o que escapa dos conjuntos: *die Rock* não está entre as formas de DER, e cai.

A frase que não passar é descartada e regerada, sem nunca chegar à tela. A checagem não
depende de confiar no modelo, e é o que torna a função aceitável.

Vale gerar de forma estruturada (saída com campos separados para a frase e para o artigo
usado) em vez de texto solto — conferir dois campos é mais barato e mais seguro que
interpretar uma frase inteira.

### As restrições que definem o desenho

**Disponibilidade.** O framework exige iOS 26 ou superior **e** aparelho com Apple
Intelligence. O alvo mínimo do projeto é iOS 18. Ou seja: dupla guarda, de versão e de
capacidade, e **a maioria dos usuários não vai ter**. A função precisa ser aditiva — o app
tem que continuar inteiro sem ela, nunca "quebrado, faltando a frase".

**As promessas da loja sobrevivem.** O modelo roda no aparelho: continua funcionando
offline, continua sem mandar nada para servidor nenhum, e a declaração *Data Not Collected*
permanece verdadeira. Isso não é detalhe — é o que permite a função existir sem reescrever a
descrição e a política de privacidade.

**A tradução da frase é o caso fácil.** Todo erro que motivou o trabalho de tradução da 1.0
foi de desambiguação de palavra solta: `der Rock` virou "pedra" porque o tradutor decidiu sem
contexto. Numa frase inteira o contexto está lá, e é onde tradução automática é forte. A
função inverte o problema em vez de herdá-lo.

Mas o SDK de tradução tem as mesmas limitações de sempre: não roda no simulador, pede
download de modelo na primeira vez, e não existe no visionOS nem no watchOS. Na prática a
frase de exemplo é **iPhone e iPad**.

**Latência.** Geração no aparelho leva segundos. "Sempre diferente" significa, por
definição, não guardar em cache — então cada palavra custa essa espera. O desenho que
resolve é gerar a frase da *próxima* palavra enquanto a atual está na tela.

### Decisão de produto pendente

A frase de exemplo é função do Pro? O encaixe é natural, mas cuidado com a combinação: ela
só funciona em aparelho novo com iOS 26. Cobrar por algo que parte dos pagantes não vai
conseguir usar precisa estar dito com todas as letras na descrição da loja, senão vira
avaliação de uma estrela.

### O que verificar quando chegar a hora

Os detalhes da API do framework de modelos da Apple mudaram entre versões e não foram
conferidos contra a documentação nesta rodada. Antes de escrever código, confirmar: o nome
exato do tipo de sessão, como se consulta a disponibilidade, e a forma da geração
estruturada.

---

## Barato agora, caro depois

| item | por que a janela fecha |
|---|---|
| Extrair as strings | a 1.1 escreve quatro telas novas; cada uma antes da extração é mais uma para caçar |
| `dailyFreeLimit` por plataforma | depois de tvOS, três plataformas dependem da constante |
| Texto da paywall separado da forma | quatro cópias divergindo, e a que diverge é a que ninguém abre |
| Catalyst ou nativo | interface de macOS escrita antes da decisão é trabalho jogado fora |
| Decidir o limite do relógio | independência sem limite mina o Pro, e voltar atrás tira algo de quem já tinha |
