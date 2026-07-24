import SwiftUI

struct TrainingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var mode: TrainingMode = .wordToArticle
    @State private var showsTranslation = false
    @State private var currentNoun: GermanNoun?
    @State private var typedAnswer = ""
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Modo", selection: $mode) {
                        ForEach(TrainingMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
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
                            Text(feedback)
                                .font(.headline)
                                .foregroundStyle(feedback.hasPrefix("Correto") ? .green : .red)
                        }
                    }
                }

                Section("Estatísticas Extras") {
                    StatisticsSummaryView()
                }
            }
            .navigationTitle("Treino")
            .onAppear {
                loadNextNoun()
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
        feedback = isCorrect ? "Correto" : "Era \(noun.article.rawValue)"
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
            feedback = isCorrect
                ? "Correto: \(matchingNoun.article.rawValue) \(matchingNoun.word)"
                : "\(matchingNoun.word) usa \(matchingNoun.article.rawValue)"
        } else {
            feedback = "Palavra não encontrada no vocabulário"
        }

        loadNextNoun(afterDelay: true)
    }

    private func exampleWord(for article: GermanArticle) -> String {
        store.nouns.first { $0.article == article }?.word ?? "palavra"
    }

    private func loadNextNoun(afterDelay: Bool = false) {
        let action = {
            currentNoun = store.nouns.randomElement()
            resetAnswer(keepsFeedback: false)
        }

        if afterDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: action)
        } else {
            action()
        }
    }

    private func resetAnswer(keepsFeedback: Bool = true) {
        typedAnswer = ""
        if !keepsFeedback {
            feedback = nil
        }
    }
}
