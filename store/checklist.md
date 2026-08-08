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

## Decidido

- [x] **Vocabulário explícito**: 33 termos removidos, base em 11.695. Classificação **4+** —
      ver `classificacao-etaria.md`
- [x] **Nome**: `DerDieDas: Artigos Alemães` — ver `nome-e-marca.md`
- [x] **iPad mantido**: layout conferido no simulador do iPad Pro 13" (usa a barra de abas
      superior do iOS 26, sem quebras) e capturas geradas em `capturas/ipad-13/`

## Ainda em aberto

- [x] **Apple Watch**: app instalado e rodando no relógio físico; capturas em 416×496
- [x] **Vision Pro**: roda no simulador; captura em 3840×2160 em `capturas/visionos/`
- [x] **Mac**: escolhido o build Catalyst, com o App Sandbox que a Mac App Store exige
- [ ] **Capturas do Mac** — o app Catalyst roda, mas capturar exige permissão de Gravação
      de Tela. Abra o app e capture com `⌘⇧4` + espaço (1280×800 ou 2560×1600).

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
