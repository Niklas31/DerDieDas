# Classificação etária — precisa de uma decisão sua

Ao gerar as capturas de tela, o treino sorteou a palavra **Transgender**. Fui olhar a
base e encontrei conteúdo que muda a resposta do questionário de classificação etária.

## O que tem na base

Auditei os 11.728 substantivos. Entre eles:

| Categoria | Exemplos |
|---|---|
| Sexual explícito | `DER Analsex`, `DER Oralsex`, `DER Hardcore-Porno`, `DAS Sexvideo`, `DAS Masturbieren`, `DER Orgasmus`, `DAS Sperma` |
| Palavrões | `DER Hurensohn` (filho da puta), `DIE Fotze`, `DIE Möse`, `DIE Scheiße`, `DAS Arschloch`, `DER Wichser`, `DIE Schlampe` |
| Insulto de ódio | `DIE Schwuchtel` (bicha) |
| Violência sexual | `DIE Vergewaltigung`, `DER Vergewaltiger` |
| Drogas | `DAS Kokain`, `DAS Heroin`, `DAS Marihuana`, `DER Drogenhandel` |
| Armas e violência | `DAS Sturmgewehr`, `DER Massenmord`, `DER Selbstmord`, `DAS Massaker` |

São **31 palavras claramente explícitas ou vulgares**, 0,26% da base. Drogas, armas e
violência são outra conversa: aparecem em qualquer dicionário sério e em qualquer
jornal, e não vejo motivo para tirar.

## Por que isso importa

O revisor da Apple testa o app. Se digitar "Sex" na busca e receber "Hardcore-Porno"
num app classificado 4+, é rejeição por classificação etária incorreta — e uma
rejeição atrasa o lançamento em dias.

Vale lembrar que a base já passou por uma limpeza parecida: `Milf`, `Hentai` e `Viagra`
foram removidas na revisão anterior. Estas 31 escaparam.

## As duas saídas

### A. Remover as 31 palavras e classificar **4+**  ← recomendo

Elas contradizem a própria premissa do app. A descrição promete "substantivos realmente
úteis do cotidiano, níveis A1 a B1" — `Hardcore-Porno` não é vocabulário A1–B1, é
exatamente o ruído que o filtro de frequência deveria ter descartado. Perde-se 0,26% da
base e o app fica utilizável por qualquer idade, inclusive em escola.

Já está pronto para aplicar: as 31 entram em `tools/corrections.json`, na chave
`remove`, e `python3 tools/apply-corrections.py` faz o resto. É só você dar o ok.

### B. Manter tudo e classificar **12+**

Defensável: é um dicionário, e dicionário registra a língua como ela é. No questionário
seria "Conteúdo sexual ou nudez: pouco frequente/leve" e "Palavrões ou humor vulgar:
pouco frequente/leve" — o que dá 12+.

O custo é que 12+ tira o app da faixa de idade escolar, que é justamente o público de
quem está começando o alemão.

**Em qualquer um dos casos, responda o questionário com honestidade.** Marcar 4+ mantendo
`Hurensohn` na base é o caminho mais curto para uma rejeição.

## Restante do questionário (vale para as duas opções)

| Pergunta | Resposta |
|---|---|
| Violência de desenho/fantasia | Nenhuma |
| Violência realista | Nenhuma |
| Conteúdo médico/tratamento | Nenhum |
| Terror/medo | Nenhum |
| Jogos de azar | Nenhum |
| Contestes | Nenhum |
| Acesso irrestrito à web | **Não** |
| Recursos sociais / interação entre usuários | **Nenhum** |
| Compartilhamento de localização | **Não** |
