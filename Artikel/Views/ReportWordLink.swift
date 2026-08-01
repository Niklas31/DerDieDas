import SwiftUI

/// Link para reportar um erro em um substantivo.
///
/// Não há servidor: abre o app de e-mail com os dados da palavra já preenchidos,
/// para a pessoa revisar e enviar. Nada sai do aparelho sem confirmação.
struct ReportWordLink: View {
    let noun: GermanNoun
    var origin: String = "iOS"

    static let contactEmail = "contato@derdiedas.app.br"

    private var mailURL: URL? {
        let subject = "DerDieDas — correção: \(noun.article.rawValue) \(noun.word)"
        let body = """
        Encontrei algo errado nesta palavra:

        Palavra:  \(noun.word)
        Artigo:   \(noun.article.rawValue)
        Tradução: \(noun.portugueseTranslation.isEmpty ? "(sem tradução)" : noun.portugueseTranslation)
        Plural:   \(noun.plural ?? "(sem plural)")

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
