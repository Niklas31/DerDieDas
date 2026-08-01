import Foundation
import AppIntents

struct GermanNoun: Identifiable, Codable, Hashable, AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Substantivo"
    static var defaultQuery = GermanNounQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(word)", subtitle: "\(portugueseTranslation)")
    }

    let article: GermanArticle
    let word: String
    let portugueseTranslation: String
    let plural: String?

    /// Identidade derivada de artigo + palavra, não armazenada no JSON.
    ///
    /// A base é compartilhada com o app web, que usa exatamente esta chave no
    /// localStorage. Manter um UUID no arquivo custava ~300 KB comprimidos (UUIDs
    /// são aleatórios e não comprimem) sem oferecer nada que `ARTIGO|palavra` não dê.
    var id: String { "\(article.rawValue)|\(word)" }

    init(
        article: GermanArticle,
        word: String,
        portugueseTranslation: String,
        plural: String? = nil
    ) {
        self.article = article
        self.word = word
        self.portugueseTranslation = portugueseTranslation
        self.plural = plural
    }

    private enum CodingKeys: String, CodingKey {
        case article
        case word
        case portugueseTranslation
        case plural
    }
}
