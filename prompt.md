# Requisitos do App de Substantivos em Alemão

## Tradução para Português

Cada substantivo deve possuir também sua tradução para português.

Atualizar o modelo:

```swift
struct GermanNoun {
    let article: String
    let word: String
    let portugueseTranslation: String
    let plural: String?
}
```

Exemplo:

```text
DER Hund
Cachorro
Plural: Hunde

DIE Blume
Flor
Plural: Blumen

DAS Haus
Casa
Plural: Häuser
```

O campo `plural` é opcional, mas deve ser considerado na interface e no armazenamento para permitir que o usuário aprenda artigo, tradução e plural juntos.

## Aba 1: Buscar

Após a busca, exibir:

```text
DER
Hund
Português:
Cachorro
Plural:
Hunde
```

Layout sugerido:

- Artigo em destaque grande.
- Palavra logo abaixo.
- Tradução em português em tamanho menor e com menor destaque visual.
- Plural em tamanho menor, quando disponível.
- Opcionalmente permitir ocultar/mostrar a tradução através de um botão 👁️ para quem quiser praticar sem dicas.

## Aba 2: Histórico

Cada item deve mostrar:

```text
DER • Hund
Cachorro
Plural: Hunde
há 2 horas
```

Se o plural não estiver disponível, ocultar essa linha.

## Aba 3: Treino

Adicionar uma configuração chamada:

```text
Mostrar tradução durante o treino
[ ] Ativado
```

### Modo A: Palavra -> Artigo

Exemplo:

```text
Hund
(Cachorro)
Plural: Hunde

DER   DIE   DAS
```

A tradução pode ser exibida ou ocultada conforme a configuração. O plural também pode ser exibido junto com a tradução quando disponível e quando a configuração estiver ativada.

### Modo B: Artigo -> Palavra

Exemplo:

```text
DER
Tradução:
Cachorro
Plural:
Hunde

Digite a palavra:
[________]
```

O usuário deve responder:

```text
Hund
```

A tradução pode ser exibida ou ocultada conforme a configuração. O plural deve seguir a mesma regra visual da tradução.

## Estatísticas Extras

Registrar também:

- Palavras mais erradas.
- Artigos com maior índice de erro (`der`, `die`, `das`).
- Última vez que cada palavra foi praticada.

Esses dados permitirão evoluir futuramente para um sistema de repetição espaçada, semelhante ao Anki.
