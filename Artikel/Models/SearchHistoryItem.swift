import Foundation

struct SearchHistoryItem: Identifiable, Codable {
    let id: UUID
    let noun: GermanNoun
    let searchedAt: Date

    init(id: UUID = UUID(), noun: GermanNoun, searchedAt: Date = Date()) {
        self.id = id
        self.noun = noun
        self.searchedAt = searchedAt
    }
}
