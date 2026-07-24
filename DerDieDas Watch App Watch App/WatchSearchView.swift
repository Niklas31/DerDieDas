import SwiftUI

struct WatchSearchView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 40)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)

                    if !store.history.isEmpty {
                        Section("Histórico") {
                            ForEach(store.history) { item in
                                nounRow(item.noun)
                            }
                        }
                    } else {
                        ContentUnavailableView("Sem Histórico", systemImage: "clock", description: Text("Suas buscas aparecerão aqui."))
                    }
                } else {
                    let results = store.searchCategorized(query)

                    if !results.exact.isEmpty {
                        Section("Exato") {
                            ForEach(results.exact) { noun in
                                nounRow(noun)
                            }
                        }
                    }

                    if !results.partial.isEmpty {
                        Section(results.exact.isEmpty ? "Resultados" : "Outros") {
                            ForEach(results.partial) { noun in
                                nounRow(noun)
                            }
                        }
                    } else if results.exact.isEmpty {
                        ContentUnavailableView("Sem Resultados", systemImage: "magnifyingglass")
                    }
                }
            }
            .navigationTitle("Buscar")
            .searchable(text: $query, prompt: "Ex: Hund")
        }
    }

    private func nounRow(_ noun: GermanNoun) -> some View {
        Button {
            store.registerSearch(for: noun)
        } label: {
            HStack(spacing: 8) {
                ArticleBadge(article: noun.article, size: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(noun.word)
                        .font(.caption.bold())
                    if let translation = store.translation(for: noun) {
                        Text(translation)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

#Preview {
    WatchSearchView()
        .environmentObject(AppStore())
}
