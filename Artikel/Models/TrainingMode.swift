import Foundation

/// Os dois sentidos do treino.
///
/// O `rawValue` é um identificador estável, não o texto da tela: ele é a chave que sai em
/// `Picker` e que um dia vai para o disco, e amarrar isso a uma frase em português
/// significaria que traduzir a interface quebra a preferência salva. O texto vive em
/// `label`. O web app já guarda `'wordToArticle'` pelo mesmo motivo.
enum TrainingMode: String, CaseIterable, Identifiable {
    case wordToArticle
    case articleToWord

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .wordToArticle: "Palavra → Artigo"
        case .articleToWord: "Artigo → Palavra"
        }
    }
}
