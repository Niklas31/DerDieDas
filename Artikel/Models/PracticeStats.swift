import Foundation

struct NounPracticeStats: Identifiable, Codable {
    let id: UUID
    let nounID: String
    let article: GermanArticle
    let word: String
    var totalAttempts: Int
    var wrongAttempts: Int
    var lastPracticedAt: Date?

    var errorRate: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(wrongAttempts) / Double(totalAttempts)
    }

    init(noun: GermanNoun) {
        self.id = UUID()
        self.nounID = noun.id
        self.article = noun.article
        self.word = noun.word
        self.totalAttempts = 0
        self.wrongAttempts = 0
        self.lastPracticedAt = nil
    }
}

struct ArticlePracticeStats: Identifiable {
    let article: GermanArticle
    let totalAttempts: Int
    let wrongAttempts: Int

    var id: String { article.id }

    var errorRate: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(wrongAttempts) / Double(totalAttempts)
    }
}
