import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                if store.history.isEmpty {
                    ContentUnavailableView(
                        "Nenhuma busca ainda",
                        systemImage: "clock",
                        description: Text("As palavras buscadas aparecerão aqui.")
                    )
                } else {
                    ForEach(store.history) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(item.noun.article.rawValue) • \(item.noun.word)")
                                .font(.headline)
                            if let translation = store.translation(for: item.noun) {
                                Text(translation)
                                    .font(.subheadline)
                            } else {
                                Text("Sem tradução em português")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let plural = item.noun.plural {
                                Text("Plural: \(plural)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.searchedAt.formattedRelative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Histórico")
        }
    }
}
