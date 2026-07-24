import Foundation
import AppIntents

struct GermanNoun: Identifiable, Codable, Hashable, AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Substantivo"
    static var defaultQuery = GermanNounQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(word)", subtitle: "\(portugueseTranslation)")
    }
    
    let id: UUID
    let article: GermanArticle
    let word: String
    let portugueseTranslation: String
    let plural: String?

    init(
        id: UUID = UUID(),
        article: GermanArticle,
        word: String,
        portugueseTranslation: String,
        plural: String? = nil
    ) {
        self.id = id
        self.article = article
        self.word = word
        self.portugueseTranslation = portugueseTranslation
        self.plural = plural
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case article
        case word
        case portugueseTranslation
        case plural
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.article = try container.decode(GermanArticle.self, forKey: .article)
        self.word = try container.decode(String.self, forKey: .word)
        self.portugueseTranslation = try container.decode(String.self, forKey: .portugueseTranslation)
        self.plural = try container.decodeIfPresent(String.self, forKey: .plural)
    }
}
