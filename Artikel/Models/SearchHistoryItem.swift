import Foundation

/// Uma busca registrada. Guarda só a **chave** do substantivo, nunca o substantivo.
///
/// Guardar o `GermanNoun` inteiro tinha dois defeitos. O menor: o histórico congelava a
/// tradução do dia em que a busca aconteceu, então corrigir a base não corrigia o que o
/// usuário via. O maior: qualquer mudança no formato de `GermanNoun` fazia o array inteiro
/// falhar ao decodificar, e `AppStore.load` engolia o erro devolvendo `[]` — o histórico de
/// todo mundo sumia em silêncio, e a próxima gravação selava a perda.
///
/// O web app sempre guardou só a chave (`docs/js/store.js`); agora os dois combinam.
struct SearchHistoryItem: Identifiable, Codable {
    let id: UUID
    /// `ARTIGO|palavra`, o mesmo `GermanNoun.id` usado como chave em todo o app.
    let nounID: String
    let searchedAt: Date

    init(id: UUID = UUID(), nounID: String, searchedAt: Date = Date()) {
        self.id = id
        self.nounID = nounID
        self.searchedAt = searchedAt
    }

    init(id: UUID = UUID(), noun: GermanNoun, searchedAt: Date = Date()) {
        self.init(id: id, nounID: noun.id, searchedAt: searchedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id, nounID, searchedAt
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case noun
    }

    /// Só os campos que formam a chave; o resto do registro antigo é descartado.
    private struct LegacyNoun: Decodable {
        let article: String
        let word: String
    }

    /// Aceita o formato antigo, que aninhava o substantivo inteiro.
    ///
    /// A tolerância mora **no elemento**, não em volta do array: assim um registro
    /// corrompido não leva junto os outros 49.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        searchedAt = try container.decodeIfPresent(Date.self, forKey: .searchedAt) ?? Date()

        if let stored = try container.decodeIfPresent(String.self, forKey: .nounID) {
            nounID = stored
            return
        }

        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
        let noun = try legacy.decode(LegacyNoun.self, forKey: .noun)
        nounID = "\(noun.article)|\(noun.word)"
    }
}

/// O par já resolvido que as telas consomem: a busca mais o substantivo atual.
///
/// Resolver na leitura é o que faz uma correção na base aparecer no histórico
/// retroativamente, em vez de ficar presa ao texto gravado na época.
struct HistoryEntry: Identifiable {
    let id: UUID
    let noun: GermanNoun
    let searchedAt: Date
}
