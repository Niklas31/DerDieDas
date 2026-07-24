import SwiftUI

struct StatisticsSummaryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            statsBlock(title: "Palavras mais erradas") {
                if store.mostMissedWords.isEmpty {
                    Text("Sem erros registrados ainda.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.mostMissedWords.prefix(5)) { stat in
                        HStack {
                            Text(stat.word)
                            Spacer()
                            Text("\(stat.wrongAttempts) erro(s)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            statsBlock(title: "Artigos com maior índice de erro") {
                ForEach(store.articleErrorStats) { stat in
                    HStack {
                        Text(stat.article.rawValue)
                        Spacer()
                        Text(stat.totalAttempts == 0 ? "Sem dados" : stat.errorRate.formatted(.percent.precision(.fractionLength(0))))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            statsBlock(title: "Última prática") {
                let practicedStats = store.nounStats
                    .filter { $0.lastPracticedAt != nil }
                    .sorted { ($0.lastPracticedAt ?? .distantPast) > ($1.lastPracticedAt ?? .distantPast) }

                if practicedStats.isEmpty {
                    Text("Nenhuma palavra praticada ainda.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(practicedStats.prefix(5)) { stat in
                        HStack {
                            Text(stat.word)
                            Spacer()
                            if let date = stat.lastPracticedAt {
                                Text(date.formattedRelative)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .font(.subheadline)
    }

    private func statsBlock<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }
}
