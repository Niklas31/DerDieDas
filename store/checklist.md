# Checklist de lançamento

Estado em 8 de agosto de 2026, com a conta de developer recém-contratada e aguardando aprovação.

## Já pronto no projeto

- [x] Bundle ID `com.nicolas.DerDieDas`
- [x] Versão 1.0, build 1
- [x] `PrivacyInfo.xcprivacy` nos dois alvos (iOS e watchOS)
- [x] `ITSAppUsesNonExemptEncryption = NO` — dispensa a papelada de exportação
- [x] Categoria Educação declarada no Info.plist
- [x] Botão "Restaurar Compras" no paywall — exigido pela diretriz 3.1.1
- [x] Política de privacidade publicada e acessível
- [x] Ícone 1024 (Icon Composer)
- [x] Textos da ficha: `ficha-app-store.md`
- [x] Capturas de iPhone 6,9": `capturas/iphone-6.9/`

## Depende de decisão sua

- [ ] **Vocabulário explícito** — ver `classificacao-etaria.md`. Bloqueia a resposta da
      classificação etária, então resolva antes de preencher a ficha.
- [ ] **Nome do app**: `DerDieDas: Artigos Alemães` ou só `DerDieDas` — ver `nome-e-marca.md`
- [ ] **Manter suporte a iPad?** O projeto declara `TARGETED_DEVICE_FAMILY = "1,2"`, o que
      **obriga** capturas de iPad 13" (2064 × 2752) e faz o revisor testar no iPad. Se você
      nunca rodou o app num iPad, há duas saídas: gerar as capturas e conferir o layout, ou
      mudar para `1` e publicar só para iPhone. Publicar só para iPhone agora e adicionar
      iPad depois é uma atualização normal, sem penalidade.
- [ ] **Publicar o app do Apple Watch junto?** Se sim, ele exige as próprias capturas.

## Depende da Apple aprovar sua conta

- [ ] Aguardar o e-mail de aprovação — de 24 h a alguns dias
- [ ] **Contratos → Acordos, Impostos e Bancos: assinar o Paid Applications**, com dados
      bancários e fiscais (CPF e o formulário W-8BEN dos EUA). **Faça isto primeiro** —
      é o passo que mais trava gente, e sem ele a compra de R$ 9,90 não funciona.
- [ ] Trocar o Team no Xcode: o `DEVELOPMENT_TEAM` atual (`YFHTZY23MD`) é o time pessoal
      gratuito; a conta paga tem um ID novo
- [ ] Registrar o App ID com a capacidade In-App Purchase
- [ ] Criar o registro do app e **reservar o nome**
- [ ] Criar a compra `com.nicolas.DerDieDas.pro` (não-consumível, R$ 9,90) com captura de revisão
- [ ] Preencher a ficha, o questionário de privacidade e a classificação etária
- [ ] Subir as capturas
- [ ] Archive → TestFlight para a família testar
- [ ] Enviar para revisão

## Questionário de privacidade (App Privacy)

A resposta é a mais simples possível: **"Não, não coletamos dados deste app."**

O app não tem conta, não tem analytics, não tem SDK de terceiros, não tem anúncios e não
faz nenhuma requisição de rede. Histórico e estatísticas ficam em `UserDefaults`, no
aparelho. A tradução sob demanda roda no dispositivo pelo framework da Apple.

Só um cuidado: se um dia entrar qualquer SDK de analytics ou anúncio, esta resposta
precisa mudar junto — declarar "não coletamos" e coletar é o tipo de coisa que derruba
a conta, não só a versão.

## Diretrizes que mais reprovam, conferidas

| Diretriz | Situação |
|---|---|
| 2.1 Completude | App funcional, sem placeholders, sem links quebrados |
| 2.3.6 Classificação incorreta | **Pendente** — ver `classificacao-etaria.md` |
| 3.1.1 Compras | Compra única via StoreKit 2, com Restaurar Compras |
| 4.1 Cópias | Nome disputado por doze apps, mas o app é original — ver `nome-e-marca.md` |
| 5.1.1 Privacidade | Nada coletado; política publicada e linkada de dentro do app |
| 5.2.1 Direitos de terceiros | Base CC BY-SA 4.0 com atribuição em Treino → ⓘ |
