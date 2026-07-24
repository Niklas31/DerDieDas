import SwiftUI

struct RootTabView: View {
    private enum AppTab: Hashable {
        case search
        case history
        case training
    }

    @State private var selectedTab: AppTab = .search

    var body: some View {
        if #available(iOS 26.0, *) {
            tabs
                .tabViewSearchActivation(.searchTabSelection)
        } else {
            tabs
        }
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
