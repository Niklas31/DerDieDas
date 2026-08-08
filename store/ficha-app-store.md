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
alemao,deutsch,artigo,substantivo,vocabulario,gramatica,flashcard,idioma,traducao,plural,a1,b1
```

Não repita palavras que já estão no nome ou no subtítulo — a Apple indexa os três campos
juntos, e repetir desperdiça caracteres.

## Texto promocional  · limite 170 · editável sem nova versão

```
11.728 substantivos alemães com artigo, tradução e plural. Busca instantânea, treino nos dois sentidos e estatísticas dos erros. Offline, sem conta e sem anúncios.
```

## Descrição  · limite 4000

```
Decorar se cada substantivo alemão é der, die ou das é o obstáculo que quase todo brasileiro encontra ao aprender o idioma. Não existe atalho fácil — e foi para atacar exatamente essa dificuldade que o DerDieDas nasceu.

UMA BASE CURADA, NÃO UM DICIONÁRIO GIGANTE
São 11.728 substantivos realmente úteis do cotidiano, cada um com artigo, tradução em português e plural. A lista partiu de mais de 90 mil palavras do Wikcionário alemão e passou por um filtro de frequência de uso: só ficaram as que aparecem pelo menos cerca de uma vez por milhão no alemão real. Isso derruba a cauda longa de termos químicos, moedas antigas e palavras que ninguém usa.

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

VERSÃO WEB GRATUITA
Quem preferir usar no computador ou no Android encontra a versão web, gratuita e ilimitada, em derdiedas.app.br.

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
| Classificação etária | **depende da decisão sobre o vocabulário — ver `classificacao-etaria.md`** |
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
(Treino → esgotar o limite diário → "Desbloquear Pro").

---

## Notas para a equipe de revisão

```
O app funciona inteiramente offline e não exige conta, login ou qualquer dado do usuário.

Como testar a compra:
1. Aba Treino.
2. Responda 10 palavras diferentes — o plano gratuito libera 10 palavras novas por dia.
3. Ao atingir o limite aparece a tela "Desbloquear Pro".
4. "DerDieDas Pro" (com.nicolas.DerDieDas.pro) é uma compra única, não-consumível, que remove o limite permanentemente. O botão "Restaurar Compras" está na mesma tela.

Observações:
- A tradução sob demanda usa o Translation framework da Apple, que roda no dispositivo. Ela não funciona no simulador e pode pedir o download do modelo de idioma na primeira vez. Todas as 11.728 palavras da base já vêm traduzidas; esse recurso só atende palavras fora da base.
- O app do Apple Watch depende do app do iPhone estar instalado.
- A base de substantivos deriva do projeto aberto german-nouns (Wikcionário alemão), licenciado sob CC BY-SA 4.0. A atribuição está em Treino → ⓘ → Créditos & Licenças.
```

---

## Capturas de tela

Geradas em `store/capturas/iphone-6.9/`, no iPhone 17 Pro Max — **1320 × 2868**, que é o
tamanho obrigatório de 6,9". Ordem sugerida:

1. `01-buscar.png` — busca por "Hund", com correspondência exata e resultados relacionados
2. `02-card.png` — a palavra em destaque, com artigo, tradução, plural e o histórico
3. `03-treino.png` — treino Palavra → Artigo, com os três botões
4. `04-estatisticas.png` — palavras mais erradas, índice de erro por artigo e última prática

**Ainda faltam:** o app declara suporte a iPad (`TARGETED_DEVICE_FAMILY = "1,2"`), o que
torna obrigatório um conjunto de capturas de iPad 13" (2064 × 2752). Se publicar o app do
Apple Watch junto, ele também exige as próprias. Ver o checklist em `checklist.md`.
