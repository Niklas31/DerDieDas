import SwiftUI

@main
struct ArtikelApp: App {
    @StateObject private var store = AppStore.shared
    @StateObject private var purchase = PurchaseStore.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchase)
        }
        // No visionOS a janela nasce larga como uma TV, e o conteúdo — uma coluna
        // única de lista — fica perdido no meio de muito vazio. Um formato retrato
        // acompanha o desenho que o app já tem no iPhone e no iPad.
        #if os(visionOS)
        .defaultSize(width: 720, height: 940)
        #endif
    }
}
