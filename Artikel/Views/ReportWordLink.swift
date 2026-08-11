import SwiftUI

/// Link para reportar um erro em um substantivo.
///
/// Não há servidor: abre o app de e-mail com os dados da palavra já preenchidos,
/// para a pessoa revisar e enviar. Nada sai do aparelho sem confirmação.
///
/// `language` não tem valor padrão de propósito. Artigo e plural são fatos do alemão e
/// valem para todo mundo, mas a tradução é de um idioma só — e um report dizendo
/// `Tradução: falda` sem dizer qual pacote é ilegível quando existem quatro. Deixar o
/// parâmetro obrigatório faz o compilador cobrar cada chamada quando os idiomas
/// chegarem, em vez de um "pt-BR" implícito mentindo em silêncio.
struct ReportWordLink: View {
    let noun: GermanNoun
    let language: String
    var origin: String = "iOS"

    static let contactEmail = "contato@derdiedas.app.br"

    private var mailURL: URL? {
        let subject = "DerDieDas [\(language)] — correção: \(noun.article.rawValue) \(noun.word)"
        let body = """
        Encontrei algo errado nesta palavra:

        Palavra:  \(noun.word)
        Artigo:   \(noun.article.rawValue)
        Plural:   \(noun.plural ?? "(sem plural)")
        Tradução: \(noun.translation.isEmpty ? "(sem tradução)" : noun.translation)
        Idioma:   \(language)

        O que está errado?


        — enviado pelo DerDieDas (\(origin))
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.contactEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }

    var body: some View {
        if let mailURL {
            Link(destination: mailURL) {
                Text("Reportar erro nesta palavra")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
