import SwiftUI

struct ArticleBadge: View {
    let article: GermanArticle
    var size: CGFloat = 20

    var body: some View {
        Text(article.rawValue)
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, size * 0.65)
            .padding(.vertical, size * 0.35)
            .background(color, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(article.rawValue)
    }

    private var color: Color {
        switch article {
        case .der:
            return .blue
        case .die:
            return .pink
        case .das:
            return .green
        }
    }
}
