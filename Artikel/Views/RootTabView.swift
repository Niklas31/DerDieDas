import SwiftUI

struct RootTabView: View {
    private enum AppTab: Hashable {
        case search
        case history
        case training
    }

    @State private var selectedTab: AppTab = .search

    var body: some View {
        // A aba de busca que vira campo de texto é exclusiva do iOS; no visionOS
        // o TabView já é um painel lateral e não tem esse comportamento.
        #if os(iOS)
        if #available(iOS 26.0, *) {
            tabs
                .tabViewSearchActivation(.searchTabSelection)
        } else {
            tabs
        }
        #else
        tabs
        #endif
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Histórico", systemImage: "clock", value: .history) {
                HistoryView()
            }

            Tab("Treino", systemImage: "graduationcap", value: .training) {
                TrainingView()
            }

            Tab(value: .search, role: .search) {
                SearchView()
            }
        }
    }
}
