import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published private(set) var nouns: [GermanNoun]
    @Published private(set) var history: [SearchHistoryItem]

    /// Índice por `ARTIGO|palavra`. O histórico resolve uma chave por linha exibida, e
    /// varrer 11.694 substantivos a cada linha custa caro num relógio.
    private var nounsByID: [String: GermanNoun] = [:]

    /// `true` quando a base empacotada não pôde ser lida e o app está com as palavras
    /// de emergência. Sem isto a falha se disfarça de "app funcionando com 10 palavras".
    @Published private(set) var didFailToLoadBase = false
    @Published private(set) var nounStats: [NounPracticeStats]
    @Published private(set) var cachedTranslations: [String: String]

    private let historyKey = "artikel.history"
    private let statsKey = "artikel.stats"
    private let translationsKey = "artikel.translations"
    private let dailyViewsKey = "artikel.dailyviews"
    private let defaults = UserDefaults.standard
    private let searchResultLimit = 300

    /// Quantas palavras novas por dia o plano gratuito libera.
    let dailyFreeLimit = 10

    @Published private(set) var viewedTodayIDs: Set<String> = []
    private var viewedTodayDay = Calendar.current.startOfDay(for: Date())

    /// Idioma da tradução. Fixo por enquanto; o seletor e a resolução pelo aparelho
    /// entram junto com o segundo pacote.
    static let defaultLanguage = "pt-BR"

    init() {
        let loaded = Self.loadBundledNouns(language: Self.defaultLanguage)
        self.nouns = loaded.nouns
        self.didFailToLoadBase = loaded.usedFallback
        self.history = Self.load(LenientArray<SearchHistoryItem>.self, key: historyKey)?.elements ?? []
        self.nounStats = Self.load([NounPracticeStats].self, key: statsKey) ?? []
        self.cachedTranslations = Self.load([String: String].self, key: translationsKey) ?? [:]
        self.nounsByID = Dictionary(loaded.nouns.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        loadDailyViews()
        discardOrphanedRecords()
    }

    /// O histórico já resolvido contra a base atual.
    ///
    /// Chaves que não casam com nada — palavra removida numa revisão da base — somem da
    /// lista em vez de virar linha vazia. `discardOrphanedRecords` as apaga do disco; isto
    /// protege a exibição no intervalo.
    var historyEntries: [HistoryEntry] {
        history.compactMap { item in
            guard let noun = nounsByID[item.nounID] else { return nil }
            return HistoryEntry(id: item.id, noun: noun, searchedAt: item.searchedAt)
        }
    }

    /// Descarta registros presos a identificadores que não existem mais.
    ///
    /// A identidade do substantivo passou de UUID para `ARTIGO|palavra`. Registros
    /// gravados pelo esquema antigo continuam decodificando — um UUID vira String sem
    /// erro —, mas nunca mais casam com palavra nenhuma. Sem esta limpeza eles ficariam
    /// congelados nas estatísticas para sempre, e praticar a mesma palavra criaria uma
    /// segunda entrada começando do zero: na prática, parece que o app parou de contar.
    ///
    /// Também cobre as palavras removidas da base na revisão das traduções.
    private func discardOrphanedRecords() {
        let validIDs = Set(nouns.map(\.id))

        let previousStats = nounStats.count
        nounStats.removeAll { !validIDs.contains($0.nounID) }
        if nounStats.count != previousStats { save(nounStats, key: statsKey) }

        let previousTranslations = cachedTranslations.count
        cachedTranslations = cachedTranslations.filter { validIDs.contains($0.key) }
        if cachedTranslations.count != previousTranslations {
            save(cachedTranslations, key: translationsKey)
        }

        let previousHistory = history.count
        history.removeAll { !validIDs.contains($0.nounID) }
        if history.count != previousHistory { save(history, key: historyKey) }

        let previousViews = viewedTodayIDs.count
        viewedTodayIDs = viewedTodayIDs.filter { validIDs.contains($0) }
        if viewedTodayIDs.count != previousViews { persistDailyViews() }
    }

    // MARK: - Limite diário (plano gratuito)

    private struct DailyViewRecord: Codable {
        var day: Date
        var ids: [String]
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

    func noun(for id: String) -> GermanNoun? {
        nounsByID[id]
    }

    func translation(for noun: GermanNoun) -> String? {
        if !noun.translation.isEmpty {
            return noun.translation
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

    /// Array que descarta o elemento ilegível em vez de se perder inteiro.
    ///
    /// `JSONDecoder().decode([T].self, …)` é tudo ou nada: um registro estragado no meio
    /// leva junto os outros 49. Para o histórico, perder uma linha é aceitável; perder a
    /// lista não é.
    private struct LenientArray<Element: Decodable>: Decodable {
        let elements: [Element]

        /// Consome uma posição sem interpretá-la, para o cursor avançar.
        private struct Skip: Decodable {
            init(from decoder: Decoder) throws {
                _ = try? decoder.singleValueContainer()
            }
        }

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            var result: [Element] = []
            while !container.isAtEnd {
                let before = container.currentIndex
                if let element = try? container.decode(Element.self) {
                    result.append(element)
                } else {
                    _ = try? container.decode(Skip.self)
                }
                // Se nenhum dos dois avançou, o laço giraria para sempre.
                if container.currentIndex == before { break }
            }
            elements = result
        }
    }

    /// Lê um valor gravado, e **preserva os bytes quando não consegue**.
    ///
    /// Antes isto era `try?` puro: um formato que mudasse virava `nil`, o chamador
    /// assumia `[]`, e a primeira gravação seguinte apagava o original para sempre.
    /// A cópia em `<chave>.salvage` transforma perda definitiva em coisa recuperável.
    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            let salvageKey = "\(key).salvage"
            if UserDefaults.standard.data(forKey: salvageKey) == nil {
                UserDefaults.standard.set(data, forKey: salvageKey)
            }
            assertionFailure("Falha ao decodificar \(key): \(error). Bytes salvos em \(salvageKey).")
            return nil
        }
    }
}

private extension AppStore {
    struct BundledNouns {
        let nouns: [GermanNoun]
        /// `true` quando caiu nas dez palavras de emergência.
        let usedFallback: Bool
    }

    /// A base como está no arquivo: fatos do alemão, mais a invariante de ordem.
    private struct NounBase: Decodable {
        let count: Int
        let digest: String
        let nouns: [GermanNoun]
    }

    /// Um pacote de idioma: traduções na mesma ordem da base.
    private struct TranslationPack: Decodable {
        let language: String
        let count: Int
        let digest: String
        let translations: [String]
    }

    /// Carrega a base empacotada e funde o pacote do idioma, **reclamando alto** ao falhar.
    ///
    /// A falha aqui é traiçoeira: o app abre, funciona e tem dez palavras. Sem um sinal,
    /// isso passa por bug de conteúdo em vez de falha de carregamento — e é exatamente o
    /// que uma mudança de formato provoca.
    ///
    /// A ordem das etapas não é negociável: **decodificar → conferir digest → fundir por
    /// índice → ordenar**. A ordenação põe os traduzidos primeiro, então fundir depois dela
    /// alinharia o pacote contra a ordem errada e produziria um dado sutilmente errado e
    /// perfeitamente plausível — o pior tipo de defeito.
    static func loadBundledNouns(language: String) -> BundledNouns {
        guard let url = Bundle.main.url(forResource: "GermanNouns", withExtension: "json") else {
            assertionFailure("GermanNouns.json não está no bundle.")
            return BundledNouns(nouns: seedNouns, usedFallback: true)
        }

        let base: NounBase
        do {
            base = try JSONDecoder().decode(NounBase.self, from: Data(contentsOf: url))
        } catch {
            assertionFailure("GermanNouns.json não pôde ser lido: \(error)")
            return BundledNouns(nouns: seedNouns, usedFallback: true)
        }

        guard !base.nouns.isEmpty, base.nouns.count == base.count else {
            assertionFailure("GermanNouns.json veio vazio ou com contagem inconsistente.")
            return BundledNouns(nouns: seedNouns, usedFallback: true)
        }

        var nouns = base.nouns
        applyPack(language: language, to: &nouns, baseDigest: base.digest)

        let ordenados = nouns.sorted { lhs, rhs in
            let lhsHasTranslation = !lhs.translation.isEmpty
            let rhsHasTranslation = !rhs.translation.isEmpty

            if lhsHasTranslation != rhsHasTranslation {
                return lhsHasTranslation
            }

            return lhs.word.localizedCaseInsensitiveCompare(rhs.word) == .orderedAscending
        }

        return BundledNouns(nouns: ordenados, usedFallback: false)
    }

    /// Aplica um pacote por índice, ou nenhum.
    ///
    /// Se digest ou contagem divergirem, o pacote é descartado **inteiro** e o app fica
    /// sem tradução naquele idioma. Aplicar pela metade produziria palavras com a tradução
    /// da vizinha, que é pior que não traduzir: parece certo e ensina errado.
    static func applyPack(language: String, to nouns: inout [GermanNoun], baseDigest: String) {
        guard let url = Bundle.main.url(forResource: language, withExtension: "json",
                                        subdirectory: "lang")
                ?? Bundle.main.url(forResource: language, withExtension: "json") else {
            assertionFailure("Pacote de idioma \(language) não está no bundle.")
            return
        }

        guard let pack = try? JSONDecoder().decode(TranslationPack.self, from: Data(contentsOf: url)) else {
            assertionFailure("Pacote \(language) não pôde ser lido.")
            return
        }

        guard pack.digest == baseDigest, pack.count == nouns.count,
              pack.translations.count == nouns.count else {
            assertionFailure("Pacote \(language) fora de sincronia com a base — descartado.")
            return
        }

        for index in nouns.indices {
            nouns[index].translation = pack.translations[index]
        }
    }

    static let seedNouns: [GermanNoun] = [
        GermanNoun(article: .der, word: "Hund", translation: "Cachorro", plural: "Hunde"),
        GermanNoun(article: .die, word: "Blume", translation: "Flor", plural: "Blumen"),
        GermanNoun(article: .das, word: "Haus", translation: "Casa", plural: "Häuser"),
        GermanNoun(article: .der, word: "Tisch", translation: "Mesa", plural: "Tische"),
        GermanNoun(article: .die, word: "Tür", translation: "Porta", plural: "Türen"),
        GermanNoun(article: .das, word: "Buch", translation: "Livro", plural: "Bücher"),
        GermanNoun(article: .der, word: "Apfel", translation: "Maçã", plural: "Äpfel"),
        GermanNoun(article: .die, word: "Zeit", translation: "Tempo", plural: nil),
        GermanNoun(article: .das, word: "Kind", translation: "Criança", plural: "Kinder"),
        GermanNoun(article: .der, word: "Stuhl", translation: "Cadeira", plural: "Stühle")
    ]
}
