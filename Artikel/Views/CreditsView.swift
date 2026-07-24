import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    // Ajuste para a URL pública da sua política de privacidade (ex.: GitHub Pages).
    private let privacyPolicyURL = URL(string: "https://niklas31.github.io/DerDieDas/")

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text("DerDieDas")
                            .font(.title2.weight(.semibold))
                        Text("Versão \(appVersion)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("Base de dados") {
                    Text("Os substantivos, artigos e plurais têm como base o projeto aberto german-nouns, compilado a partir do Wikcionário alemão (WiktionaryDE) e publicado sob a licença Creative Commons Atribuição-CompartilhaIgual 4.0 (CC BY-SA 4.0). As traduções para o português da lista inicial foram curadas para este app.")
                        .font(.subheadline)

                    Link(destination: URL(string: "https://github.com/gambolputty/german-nouns")!) {
                        Label("Projeto german-nouns", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Link(destination: URL(string: "https://de.wiktionary.org")!) {
                        Label("WiktionaryDE", systemImage: "book")
                    }
                    Link(destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/deed.pt_BR")!) {
                        Label("Licença CC BY-SA 4.0", systemImage: "doc.text")
                    }
                }

                Section("Tradução") {
                    Text("As traduções geradas sob demanda usam o framework de tradução nativo da Apple, processado no próprio dispositivo. Requer iOS 18 ou superior.")
                        .font(.subheadline)
                }

                if let privacyPolicyURL {
                    Section("Privacidade") {
                        Link(destination: privacyPolicyURL) {
                            Label("Política de Privacidade", systemImage: "hand.raised")
                        }
                    }
                }
            }
            .navigationTitle("Créditos & Licenças")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluído") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CreditsView()
}
