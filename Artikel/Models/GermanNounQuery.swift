import Foundation
import AppIntents

struct GermanNounQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [GermanNoun.ID]) async throws -> [GermanNoun] {
        let store = AppStore.shared
        return store.nouns.filter { identifiers.contains($0.id) }
    }
    
    @MainActor
    func suggestedEntities() async throws -> [GermanNoun] {
        let store = AppStore.shared
        return Array(store.nouns.prefix(20))
    }
    
    @MainActor
    func entities(matching string: String) async throws -> [GermanNoun] {
        let store = AppStore.shared
        let results = store.searchCategorized(string)
        return results.exact + results.partial
    }
}
