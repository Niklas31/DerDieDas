import SwiftUI

struct TrainingView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var purchase: PurchaseStore
    @State private var mode: TrainingMode = .wordToArticle
    @State private var showsTranslation = false
    @State private var currentNoun: GermanNoun?
    @State private var typedAnswer = ""
    @State private var feedback: Feedback?

    /// O acerto vem como dado, não como formato do texto.
    ///
    /// Antes a cor saía de `feedback.hasPrefix("Correto")` — traduzir a interface teria
    /// pintado todo acerto de vermelho, e nada no compilador avisaria.
    private struct Feedback {
        let text: String
        let isCorrect: Bool
    }
    @State private var showsCredits = false
    @State private var showsPaywall = false
    @State private var reachedLimit = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Modo", selection: $mode) {
                        ForEach(TrainingMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    Toggle("Mostrar tradução durante o treino", isOn: $showsTranslation)
                }

                if let noun = currentNoun {
                    Section {
                        switch mode {
                        case .wordToArticle:
                            wordToArticle(noun)
                        case .articleToWord:
                            articleToWord(noun)
                        }
                    }

                    if let feedback {
                        Section {
                            Text(feedback.text)
                                .font(.headline)
                                .foregroundStyle(feedback.isCorrect ? .green : .red)
                        }
                    }

                    Section {
                        HStack {
                            Spacer()
                            ReportWordLink(noun: noun)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                if reachedLimit && !purchase.isPro {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.tint)
                            Text("Você atingiu o limite de \(store.dailyFreeLimit) palavras novas de hoje.")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text("Desbloqueie o DerDieDas Pro para treinar sem limites.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Desbloquear Pro") {
                                showsPaywall = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                } else if !purchase.isPro {
                    Section {
                        Label("Restam \(store.remainingFreeViews) de \(store.dailyFreeLimit) palavras grátis hoje", systemImage: "gauge.with.dots.needle.33percent")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Estatísticas Extras") {
                    StatisticsSummaryView()
                }
            }
            .navigationTitle("Treino")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsCredits = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Sobre e créditos")
                }
            }
            .sheet(isPresented: $showsCredits) {
                CreditsView()
            }
            .sheet(isPresented: $showsPaywall) {
                PaywallView()
            }
            .onAppear {
                // Quem é Pro nunca fica travado, mesmo que tenha batido o limite antes de comprar.
                if currentNoun == nil && (purchase.isPro || !reachedLimit) {
                    loadNextNoun()
                }
            }
            .onChange(of: purchase.isPro) { _, isPro in
                // Ao desbloquear o Pro, retoma o treino na hora: sem isto a tela ficaria
                // sem palavra até o app ser reaberto, porque reachedLimit continuava true.
                guard isPro else { return }
                reachedLimit = false
                if currentNoun == nil {
                    loadNextNoun()
                }
            }
            .onChange(of: mode) {
                resetAnswer()
            }
        }
    }

    private func wordToArticle(_ noun: GermanNoun) -> some View {
        VStack(spacing: 18) {
            Text(noun.word)
                .font(.system(size: 36, weight: .bold, design: .rounded))

            translationBlock(for: noun)

            HStack {
                ForEach(GermanArticle.allCases) { article in
                    Button(article.rawValue) {
                        submitArticle(article, for: noun)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(article == .der ? .blue : article == .die ? .pink : .green)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func articleToWord(_ noun: GermanNoun) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                ArticleBadge(article: noun.article, size: 34)
                Spacer()
            }

            Text("Digite qualquer substantivo do vocabulário que use este artigo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Ex.: \(exampleWord(for: noun.article))", text: $typedAnswer)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit {
                    submitWord(for: noun)
                }

            Button("Responder") {
                submitWord(for: noun)
            }
            .buttonStyle(.borderedProminent)
            .disabled(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func translationBlock(for noun: GermanNoun) -> some View {
        if showsTranslation {
            let translation = store.translation(for: noun)

            VStack(spacing: 4) {
                Text("Tradução:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(translation ?? "Sem tradução em português")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(translation == nil ? .secondary : .primary)
                if let plural = noun.plural {
                    Text("Plural: \(plural)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func submitArticle(_ article: GermanArticle, for noun: GermanNoun) {
        let isCorrect = article == noun.article
        store.recordPractice(noun: noun, isCorrect: isCorrect)
        feedback = Feedback(
            text: isCorrect ? String(localized: "Correto") : String(localized: "Era \(noun.article.rawValue)"),
            isCorrect: isCorrect
        )
        loadNextNoun(afterDelay: true)
    }

    private func submitWord(for noun: GermanNoun) {
        let answer = typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchingNoun = store.nouns.first { candidate in
            answer.compare(candidate.word, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        let isCorrect = matchingNoun?.article == noun.article

        store.recordPractice(noun: matchingNoun ?? noun, isCorrect: isCorrect)

        if let matchingNoun {
            feedback = Feedback(
                text: isCorrect
                    ? String(localized: "Correto: \(matchingNoun.article.rawValue) \(matchingNoun.word)")
                    : String(localized: "\(matchingNoun.word) usa \(matchingNoun.article.rawValue)"),
                isCorrect: isCorrect
            )
        } else {
            feedback = Feedback(
                text: String(localized: "Palavra não encontrada no vocabulário"),
                isCorrect: false
            )
        }

        loadNextNoun(afterDelay: true)
    }

    private func exampleWord(for article: GermanArticle) -> String {
        store.nouns.first { $0.article == article }?.word ?? "palavra"
    }

    private func loadNextNoun(afterDelay: Bool = false) {
        let action = {
            if let next = pickNextNoun() {
                currentNoun = next
                reachedLimit = false
                resetAnswer(keepsFeedback: false)
            } else {
                currentNoun = nil
                reachedLimit = true
            }
        }

        if afterDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: action)
        } else {
            action()
        }
    }

    /// Sorteia a próxima palavra respeitando o limite diário do plano gratuito.
    private func pickNextNoun() -> GermanNoun? {
        guard let candidate = store.nouns.randomElement() else { return nil }
        if purchase.isPro || store.registerFreeView(of: candidate) {
            return candidate
        }
        return nil
    }

    private func resetAnswer(keepsFeedback: Bool = true) {
        typedAnswer = ""
        if !keepsFeedback {
            feedback = nil
        }
    }
}
