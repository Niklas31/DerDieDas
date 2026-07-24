import Foundation

enum GermanArticle: String, CaseIterable, Codable, Identifiable {
    case der = "DER"
    case die = "DIE"
    case das = "DAS"

    var id: String { rawValue }
}
