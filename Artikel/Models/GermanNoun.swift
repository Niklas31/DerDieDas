import Foundation
import AppIntents

struct GermanNoun: Identifiable, Codable, Hashable, AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Substantivo"
    static var defaultQuery = GermanNounQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(word)", subtitle: "\(translation)")
    }

    let article: GermanArticle
    let word: String
    let plural: String?

    /// Tradução no idioma ativo. **Não vem do JSON da base** — o `AppStore` a preenche
    /// a partir do pacote de idioma carregado, logo depois de decodificar.
    ///
    /// Fica fora de `CodingKeys` de propósito: a base guarda só fatos do alemão, que não
    /// mudam com o idioma, e os pacotes ficam em arquivos próprios baixados sob demanda.
    var translation: String = ""

    /// Identidade derivada de artigo + palavra, não armazenada no JSON.
    ///
    /// A base é compartilhada com o app web, que usa exatamente esta chave no
    /// localStorage. Manter um UUID no arquivo custava ~300 KB comprimidos (UUIDs
    /// são aleatórios e não comprimem) sem oferecer nada que `ARTIGO|palavra` não dê.
    var id: String { "\(article.rawValue)|\(word)" }

    init(
        article: GermanArticle,
        word: String,
        translation: String = "",
        plural: String? = nil
    ) {
        self.article = article
        self.word = word
        self.translation = translation
        self.plural = plural
    }

    private enum CodingKeys: String, CodingKey {
        case article
        case word
        case plural
    }

    /// Igualdade e hash **só pela identidade**.
    ///
    /// O sintetizado incluiria `translation`, e a mesma palavra passaria a ter hash
    /// diferente conforme o idioma ativo — quebrando qualquer `Set`, dicionário ou
    /// identidade de `ForEach` que atravesse uma troca de idioma.
    static func == (lhs: GermanNoun, rhs: GermanNoun) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
