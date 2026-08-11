import SwiftUI

// A tradução sob demanda existe só no iPhone e no iPad: o framework Translation da
// Apple não existe no visionOS nem no watchOS, e no Mac Catalyst só a partir do
// macOS 26. Nas outras plataformas o app perde apenas a tradução de palavras fora
// da base — as 11.695 da base já vêm traduzidas.
#if os(iOS) && !targetEnvironment(macCatalyst)
import Translation
#endif

struct SearchView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var purchase: PurchaseStore
    @State private var query: String = ""
    @State private var selectedNoun: GermanNoun?
    @State private var showsTranslation = true
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var translationConfiguration: TranslationSession.Configuration?
    #endif
    @State private var translationTarget: GermanNoun?
    @State private var isTranslating = false
    @State private var translationError: String?
    @State private var showsPaywall = false

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if let selectedNoun {
                        selectedNounCard(selectedNoun)
                            .listRowSeparator(.hidden)
                    }

                    if !purchase.isPro {
                        Section {
                            Label("Restam \(store.remainingFreeViews) de \(store.dailyFreeLimit) palavras grátis hoje", systemImage: "gauge.with.dots.needle.33percent")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    let historico = store.historyEntries
                    if !historico.isEmpty {
                        Section("Histórico") {
                            ForEach(historico) { item in
                                nounRow(item.noun)
                            }
                        }
                    }
                } else {
                    let results = store.searchCategorized(query)

                    if !results.exact.isEmpty {
                        Section("Correspondência Exata") {
                            ForEach(results.exact) { noun in
                                nounRow(noun)
                            }
                        }
                    }

                    if !results.partial.isEmpty {
                        Section(results.exact.isEmpty ? "Resultados" : "Outros Resultados") {
                            ForEach(results.partial) { noun in
                                nounRow(noun)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Buscar")
            .searchable(text: $query, placement: .toolbar, prompt: "Hund, cachorro, DER...")
            .sheet(isPresented: $showsPaywall) {
                PaywallView()
            }
            .onAppear {
                selectedNoun = selectedNoun ?? store.nouns.randomElement()
            }
            #if os(iOS) && !targetEnvironment(macCatalyst)
            .translationTask(translationConfiguration) { session in
                guard let translationTarget else { return }

                do {
                    let response = try await session.translate(translationTarget.word)
                    store.saveTranslation(response.targetText, for: translationTarget)
                    translationError = nil
                } catch {
                    translationError = "Não foi possível traduzir agora."
                }

                isTranslating = false
            }
            #endif
        }
    }

    private func nounRow(_ noun: GermanNoun) -> some View {
        Button {
            guard reveal(noun) else { return }
            selectedNoun = noun
            query = ""
            store.registerSearch(for: noun)
        } label: {
            HStack(spacing: 12) {
                ArticleBadge(article: noun.article, size: 14)
                VStack(alignment: .leading, spacing: 4) {
                    Text(noun.word)
                        .font(.headline)
                    Text(store.translation(for: noun) ?? "Sem tradução em português")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func selectedNounCard(_ noun: GermanNoun) -> some View {
        let translation = store.translation(for: noun)

        return VStack(spacing: 12) {
            HStack {
                Spacer()
                Button {
                    showsTranslation.toggle()
                } label: {
                    Image(systemName: showsTranslation ? "eye" : "eye.slash")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(showsTranslation ? "Ocultar tradução" : "Mostrar tradução")
            }

            ArticleBadge(article: noun.article, size: 34)

            Text(noun.word)
                .font(.system(size: 34, weight: .semibold, design: .rounded))

            if showsTranslation {
                VStack(spacing: 4) {
                    Text("Português:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let translation {
                        Text(translation)
                            .font(.title3.weight(.medium))
                    } else {
                        Text("Sem tradução em português")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    if let plural = noun.plural {
                        Text("Plural: \(plural)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    #if os(iOS) && !targetEnvironment(macCatalyst)
                    if noun.portugueseTranslation.isEmpty {
                        Button {
                            translate(noun)
                        } label: {
                            Label(translation == nil ? "Traduzir" : "Atualizar tradução", systemImage: "translate")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTranslating)
                        .padding(.top, 8)
                    }
                    #endif

                    if isTranslating, translationTarget?.id == noun.id {
                        ProgressView()
                            .padding(.top, 4)
                    }

                    if let translationError, translationTarget?.id == noun.id {
                        Text(translationError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            ReportWordLink(noun: noun)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    /// Libera a exibição da palavra (Pro é sempre liberado). Se o limite gratuito acabou, abre a paywall.
    private func reveal(_ noun: GermanNoun) -> Bool {
        if purchase.isPro || store.registerFreeView(of: noun) {
            return true
        }
        showsPaywall = true
        return false
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    private func translate(_ noun: GermanNoun) {
        translationTarget = noun
        translationError = nil
        isTranslating = true

        if translationConfiguration == nil {
            translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "de"),
                target: Locale.Language(identifier: "pt-BR")
            )
        } else {
            translationConfiguration?.invalidate()
        }
    }
    #endif
}
#Preview {
    SearchView()
        .environmentObject(AppStore())
        .environmentObject(PurchaseStore.shared)
}

