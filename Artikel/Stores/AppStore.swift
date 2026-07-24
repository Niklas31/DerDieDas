import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published private(set) var nouns: [GermanNoun]
    @Published private(set) var history: [SearchHistoryItem]
    @Published private(set) var nounStats: [NounPracticeStats]
    @Published private(set) var cachedTranslations: [UUID: String]

    private let historyKey = "artikel.history"
    private let statsKey = "artikel.stats"
    private let translationsKey = "artikel.translations"
    private let dailyViewsKey = "artikel.dailyviews"
    private let defaults = UserDefaults.standard
    private let searchResultLimit = 300

    /// Quantas palavras novas por dia o plano gratuito libera.
    let dailyFreeLimit = 10

    @Published private(set) var viewedTodayIDs: Set<UUID> = []
    private var viewedTodayDay = Calendar.current.startOfDay(for: Date())

    init() {
        self.nouns = Self.loadBundledNouns()
        self.history = Self.load([SearchHistoryItem].self, key: historyKey) ?? []
        self.nounStats = Self.load([NounPracticeStats].self, key: statsKey) ?? []
        self.cachedTranslations = Self.load([UUID: String].self, key: translationsKey) ?? [:]
        loadDailyViews()
    }

    // MARK: - Limite diário (plano gratuito)

    private struct DailyViewRecord: Codable {
        var day: Date
        var ids: [UUID]
    }

    var remainingFreeViews: Int {
        max(0, dailyFreeLimit - viewedTodayIDs.count)
    }

    func hasSeenToday(_ noun: GermanNoun) -> Bool {
        viewedTodayIDs.contains(noun.id)
    }

    /// Tenta liberar a exibição de uma palavra no plano gratuito.
    /// Rever uma palavra já vista hoje é sempre liberado. Retorna `false` quando o limite foi atingido.
    func registerFreeView(of noun: GermanNoun) -> Bool {
        rolloverIfNeeded()
        if viewedTodayIDs.contains(noun.id) { return true }
        guard viewedTodayIDs.count < dailyFreeLimit else { return false }
        viewedTodayIDs.insert(noun.id)
        persistDailyViews()
        return true
    }

    private func loadDailyViews() {
        let today = Calendar.current.startOfDay(for: Date())
        if let record = Self.load(DailyViewRecord.self, key: dailyViewsKey),
           Calendar.current.isDate(record.day, inSameDayAs: today) {
            viewedTodayDay = record.day
            viewedTodayIDs = Set(record.ids)
        } else {
            viewedTodayDay = today
            viewedTodayIDs = []
        }
    }

    private func rolloverIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(viewedTodayDay, inSameDayAs: today) {
            viewedTodayDay = today
            viewedTodayIDs = []
            persistDailyViews()
        }
    }

    private func persistDailyViews() {
        save(DailyViewRecord(day: viewedTodayDay, ids: Array(viewedTodayIDs)), key: dailyViewsKey)
    }

    func search(_ query: String) -> [GermanNoun] {
        let results = searchCategorized(query)
        return results.exact + results.partial
    }

    struct SearchResults {
        let exact: [GermanNoun]
        let partial: [GermanNoun]
    }

    func searchCategorized(_ query: String) -> SearchResults {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return SearchResults(exact: [], partial: Array(nouns.prefix(searchResultLimit)))
        }

        var exact: [GermanNoun] = []
        var partial: [GermanNoun] = []
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

        let filtered = nouns.lazy.filter { noun in
            noun.word.range(of: trimmedQuery, options: options) != nil
                || self.translation(for: noun)?.range(of: trimmedQuery, options: options) != nil
                || noun.article.rawValue.range(of: trimmedQuery, options: options) != nil
                || (noun.plural?.range(of: trimmedQuery, options: options) != nil)
        }

        for noun in filtered {
            let wordMatch = noun.word.compare(trimmedQuery, options: options, range: nil, locale: .current) == .orderedSame
            let translationMatch = self.translation(for: noun)?.compare(trimmedQuery, options: options, range: nil, locale: .current) == .orderedSame

            if wordMatch || translationMatch {
                exact.append(noun)
            } else {
                partial.append(noun)
            }

            if exact.count + partial.count >= searchResultLimit {
                break
            }
        }

        return SearchResults(exact: exact, partial: partial)
    }

    func registerSearch(for noun: GermanNoun) {
        history.insert(SearchHistoryItem(noun: noun), at: 0)
        history = Array(history.prefix(50))
        save(history, key: historyKey)
    }

    func recordPractice(noun: GermanNoun, isCorrect: Bool) {
        var stats = nounStats.first { $0.nounID == noun.id } ?? NounPracticeStats(noun: noun)
        stats.totalAttempts += 1
        stats.wrongAttempts += isCorrect ? 0 : 1
        stats.lastPracticedAt = Date()

        nounStats.removeAll { $0.nounID == noun.id }
        nounStats.append(stats)
        save(nounStats, key: statsKey)
    }

    var mostMissedWords: [NounPracticeStats] {
        nounStats
            .filter { $0.wrongAttempts > 0 }
            .sorted {
                if $0.wrongAttempts == $1.wrongAttempts {
                    return $0.errorRate > $1.errorRate
                }
                return $0.wrongAttempts > $1.wrongAttempts
            }
    }

    var articleErrorStats: [ArticlePracticeStats] {
        GermanArticle.allCases.map { article in
            let matchingStats = nounStats.filter { $0.article == article }
            return ArticlePracticeStats(
                article: article,
                totalAttempts: matchingStats.reduce(0) { $0 + $1.totalAttempts },
                wrongAttempts: matchingStats.reduce(0) { $0 + $1.wrongAttempts }
            )
        }
        .sorted { $0.errorRate > $1.errorRate }
    }

    func noun(for id: UUID) -> GermanNoun? {
        nouns.first { $0.id == id }
    }

    func translation(for noun: GermanNoun) -> String? {
        if !noun.portugueseTranslation.isEmpty {
            return noun.portugueseTranslation
        }

        return cachedTranslations[noun.id]
    }

    func saveTranslation(_ translation: String, for noun: GermanNoun) {
        let cleanedTranslation = translation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTranslation.isEmpty else { return }

        cachedTranslations[noun.id] = cleanedTranslation
        save(cachedTranslations, key: translationsKey)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

private extension AppStore {
    static func loadBundledNouns() -> [GermanNoun] {
        guard
            let url = Bundle.main.url(forResource: "GermanNouns", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let nouns = try? JSONDecoder().decode([GermanNoun].self, from: data)
        else {
            return seedNouns
        }

        return nouns.sorted { lhs, rhs in
            let lhsHasTranslation = !lhs.portugueseTranslation.isEmpty
            let rhsHasTranslation = !rhs.portugueseTranslation.isEmpty

            if lhsHasTranslation != rhsHasTranslation {
                return lhsHasTranslation
            }

            return lhs.word.localizedCaseInsensitiveCompare(rhs.word) == .orderedAscending
        }
    }

    static let seedNouns: [GermanNoun] = [
        GermanNoun(article: .der, word: "Hund", portugueseTranslation: "Cachorro", plural: "Hunde"),
        GermanNoun(article: .die, word: "Blume", portugueseTranslation: "Flor", plural: "Blumen"),
        GermanNoun(article: .das, word: "Haus", portugueseTranslation: "Casa", plural: "Häuser"),
        GermanNoun(article: .der, word: "Tisch", portugueseTranslation: "Mesa", plural: "Tische"),
        GermanNoun(article: .die, word: "Tür", portugueseTranslation: "Porta", plural: "Türen"),
        GermanNoun(article: .das, word: "Buch", portugueseTranslation: "Livro", plural: "Bücher"),
        GermanNoun(article: .der, word: "Apfel", portugueseTranslation: "Maçã", plural: "Äpfel"),
        GermanNoun(article: .die, word: "Zeit", portugueseTranslation: "Tempo", plural: nil),
        GermanNoun(article: .das, word: "Kind", portugueseTranslation: "Criança", plural: "Kinder"),
        GermanNoun(article: .der, word: "Stuhl", portugueseTranslation: "Cadeira", plural: "Stühle")
    ]
}
