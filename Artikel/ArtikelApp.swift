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
    }
}
