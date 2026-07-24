import Foundation

enum TrainingMode: String, CaseIterable, Identifiable {
    case wordToArticle = "Palavra -> Artigo"
    case articleToWord = "Artigo -> Palavra"

    var id: String { rawValue }
}
