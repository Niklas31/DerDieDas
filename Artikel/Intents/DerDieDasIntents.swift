import AppIntents
import SwiftUI

struct LookupNounIntent: AppIntent {
    static var title: LocalizedStringResource = "Procurar Artigo"
    static var description = IntentDescription("Procura o artigo de um substantivo em alemão.")

    @Parameter(title: "Palavra", description: "O substantivo que você deseja procurar", requestValueDialog: IntentDialog("Qual palavra você deseja procurar?"))
    var word: String

    static var parameterSummary: some ParameterSummary {
        Summary("Procurar o artigo de \(\.$word)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        let store = AppStore.shared
        let results = store.searchCategorized(word)
        
        // Prioriza resultados exatos. Se houver resultados exatos, mostra apenas eles.
        // Se não houver nenhum exato, mostra os parciais.
        let matchesToShow = results.exact.isEmpty ? results.partial : results.exact
        
        guard !matchesToShow.isEmpty else {
            let dialog = IntentDialog("Não encontrei o artigo para '\(word)'.")
            // Vazio, não "Não encontrado": este valor é lido por automações dos Atalhos,
            // que comparariam com uma frase em português e quebrariam ao traduzir. O texto
            // que a pessoa ouve continua no diálogo.
            return .result(value: "", dialog: dialog)
        }

        if matchesToShow.count == 1 {
            let noun = matchesToShow[0]
            let dialog = IntentDialog("O artigo de \(noun.word) é \(noun.article.rawValue).")
            let snippet = ArticleSnippetView(nouns: [noun])
            return .result(value: noun.article.rawValue, dialog: dialog, view: snippet)
        } else {
            let dialog = IntentDialog("Encontrei \(matchesToShow.count) resultados para '\(word)'.")
            let snippet = ArticleSnippetView(nouns: matchesToShow)
            return .result(value: matchesToShow[0].article.rawValue, dialog: dialog, view: snippet)
        }
    }
}

struct ArticleSnippetView: View {
    let nouns: [GermanNoun]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(nouns.prefix(5)) { noun in
                HStack(spacing: 16) {
                    ArticleBadge(article: noun.article, size: 20)
                    
                    VStack(alignment: .leading) {
                        Text(noun.word)
                            .font(.headline)
                        if let plural = noun.plural {
                            Text("Plural: \(plural)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                
                if noun.id != nouns.prefix(5).last?.id {
                    Divider()
                        .padding(.leading, 60)
                }
            }
            
            if nouns.count > 5 {
                Text("... e mais \(nouns.count - 5) resultados")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}

struct DerDieDasShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LookupNounIntent(),
            phrases: [
                "Qual o artigo no \(.applicationName)",
                "Procurar artigo no \(.applicationName)",
                "Ver artigo no \(.applicationName)",
                "What is the article in \(.applicationName)",
                "Search article in \(.applicationName)",
                "Check article in \(.applicationName)"
            ],
            shortTitle: "Procurar Artigo",
            systemImageName: "magnifyingglass"
        )
    }
}
