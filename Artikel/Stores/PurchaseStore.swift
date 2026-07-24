import Foundation
import StoreKit

@MainActor
final class PurchaseStore: ObservableObject {
    static let shared = PurchaseStore()

    /// Identificador do produto não-consumível (deve bater com o App Store Connect e o arquivo .storekit).
    let productID = "com.nicolas.DerDieDas.pro"

    @Published private(set) var isPro = false
    @Published private(set) var proProduct: Product?
    @Published private(set) var isPurchasing = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            proProduct = products.first
        } catch {
            lastError = "Não foi possível carregar a loja."
        }
    }

    @discardableResult
    func purchase() async -> Bool {
        if proProduct == nil {
            await loadProducts()
        }
        guard let proProduct else {
            lastError = "Produto indisponível no momento."
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await proProduct.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = "Não foi possível verificar a compra."
                    return false
                }
                await transaction.finish()
                isPro = true
                return true
            case .userCancelled:
                return false
            case .pending:
                lastError = "Compra aguardando aprovação."
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = "A compra falhou. Tente novamente."
            return false
        }
    }

    func restore() async {
        do {
            try await StoreKit.AppStore.sync()
        } catch {
            // AppStore.sync() lança erro se o usuário cancelar o login; apenas revalidamos.
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }
}
