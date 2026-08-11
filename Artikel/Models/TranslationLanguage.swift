import Foundation

/// Idioma da tradução — o alemão nunca muda, só a coluna traduzida.
///
/// O `rawValue` é o nome do pacote em `docs/data/lang/<rawValue>.json` e a chave usada no
/// `UserDefaults`. **Nunca mude um rawValue existente**: ele já está gravado no aparelho
/// de quem escolheu, e trocá-lo faz a escolha da pessoa virar um valor desconhecido.
enum TranslationLanguage: String, CaseIterable, Identifiable, Codable {
    case ptBR = "pt-BR"
    case en = "en"

    var id: String { rawValue }

    /// Nome do idioma **no próprio idioma**, e não traduzido.
    ///
    /// Um seletor de idioma existe para quem não entende a língua atual da interface. Se
    /// os nomes fossem traduzidos, quem abrisse o app em português veria "Inglês" — e
    /// quem precisa da opção é justamente quem procura a palavra "English".
    var label: String {
        switch self {
        case .ptBR: return "Português (Brasil)"
        case .en: return "English"
        }
    }

    /// Usado quando o aparelho não fala nenhum idioma que temos.
    ///
    /// Inglês, e não português: é o segundo idioma mais provável de quem estuda alemão em
    /// qualquer lugar do mundo. Quem tem aparelho em português continua caindo em `ptBR`
    /// pela escada normal, então esta escolha só afeta quem hoje recebe português sem
    /// entender por quê.
    static let fallback = TranslationLanguage.en

    /// Casa uma etiqueta BCP-47 com um pacote, colapsando região.
    ///
    /// `pt-PT`, `pt-AO` e `pt` caem em `pt-BR`: o português europeu tem diferenças reais,
    /// mas ler "chuveiro" em vez de "chuveiro/duche" é incomparavelmente melhor que ler
    /// inglês. Mesma lógica para `es-419` quando o espanhol chegar.
    static func match(_ tag: String) -> TranslationLanguage? {
        let normalized = tag.lowercased().replacingOccurrences(of: "_", with: "-")
        if let exact = TranslationLanguage(rawValue: normalized) {
            return exact
        }
        if let exact = allCases.first(where: { $0.rawValue.lowercased() == normalized }) {
            return exact
        }
        let base = normalized.split(separator: "-").first.map(String.init) ?? normalized
        switch base {
        case "pt": return .ptBR
        case "en": return .en
        default: return nil
        }
    }

    /// Decide o idioma: escolha explícita, senão o aparelho, senão o padrão.
    ///
    /// `override` é `nil` enquanto a pessoa não escolher nada — e é isso que faz o app
    /// seguir o aparelho. **O valor resolvido não deve ser gravado**: gravá-lo congelaria
    /// no primeiro lançamento o idioma que o aparelho tinha naquele dia, e trocar o idioma
    /// do iPhone depois não mudaria mais nada.
    ///
    /// `preferred` vem em ordem de preferência (`Locale.preferredLanguages`), então quem
    /// tem alemão em primeiro e inglês em segundo recebe inglês, e não o padrão.
    static func resolve(override: String?, preferred: [String]) -> TranslationLanguage {
        if let override, let escolhido = match(override) {
            return escolhido
        }
        for tag in preferred {
            if let encontrado = match(tag) {
                return encontrado
            }
        }
        return fallback
    }
}
