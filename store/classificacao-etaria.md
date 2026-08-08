# Classificação etária: **4+**

**Decidido:** as palavras explícitas saíram da base e o app vai como 4+.

## Como isso apareceu

Ao gerar as capturas de tela, o treino sorteou a palavra **Transgender**. Fui olhar a
base e encontrei conteúdo que mudava a resposta do questionário: **33 termos explícitos**
entre os 11.728 substantivos — `Hardcore-Porno`, `Analsex`, `Oralsex`, `Sexvideo`,
`Telefonsex`, `Hurensohn`, `Fotze`, `Möse`, `Schwuchtel` (insulto de ódio), `Scheiße`,
`Arschloch`, `Wichser`, `Vergewaltigung`.

O risco era concreto: se o revisor da Apple digitasse "Sex" num app marcado 4+ e
recebesse "Hardcore-Porno", é rejeição por classificação incorreta — e uma rejeição
atrasa o lançamento em dias.

## O critério usado

**Sai** o registro pornográfico, de sexo comercial e de palavrão/insulto. Não é
vocabulário A1–B1 e contradiz a própria descrição do app, que promete "substantivos
realmente úteis do cotidiano". É exatamente o ruído que o filtro de frequência do Colab
deveria ter descartado — a mesma limpeza que já tinha tirado `Milf`, `Hentai` e `Viagra`.

**Fica** o vocabulário clínico, anatômico e de identidade: `Penis`, `Vagina`, `Hoden`,
`Kondom`, `Sexualität`, `Homosexualität`, `Homosexuelle`, `Heterosexuelle`,
`Transsexuelle`, `Sexismus`. Está em qualquer dicionário e em qualquer aula de biologia,
é apropriado para 4+, e tirar os termos de identidade mantendo `Heterosexuelle` seria
discriminatório além de errado como dicionário.

**Fica também** o vocabulário de drogas, armas e violência — `Kokain`, `Sturmgewehr`,
`Massenmord`, `Selbstmord`. São palavras de jornal, presentes em qualquer dicionário
sério, e a classificação da Apple trata de conteúdo apresentado como conteúdo, não de
verbetes num material de referência.

A base foi de **11.728 para 11.695** substantivos — 0,28%. As remoções estão versionadas
em `tools/corrections.json`, na chave `remove.explicito`, e são reaplicáveis com
`python3 tools/apply-corrections.py`.

## Questionário de classificação

| Pergunta | Resposta |
|---|---|
| Conteúdo sexual ou nudez | **Nenhum** |
| Palavrões ou humor vulgar | **Nenhum** |
| Violência de desenho/fantasia | Nenhuma |
| Violência realista | Nenhuma |
| Conteúdo médico/tratamento | Nenhum |
| Terror/medo | Nenhum |
| Jogos de azar | Nenhum |
| Contestes | Nenhum |
| Acesso irrestrito à web | **Não** |
| Recursos sociais / interação entre usuários | **Nenhum** |
| Compartilhamento de localização | **Não** |

Resultado: **4+**.

## Se um reporte trouxer outro caso

O botão "Reportar erro nesta palavra" existe justamente para isso. Palavra nova que
destoe entra em `remove.explicito` no mesmo arquivo, e a próxima versão sai limpa —
sem precisar mexer na classificação.
