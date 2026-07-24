import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchase: PurchaseStore
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text("DerDieDas Pro")
                            .font(.title.weight(.bold))
                        Text("Desbloqueie o app inteiro — para sempre.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 16) {
                        benefit("infinity", "Palavras ilimitadas", "Busque e treine sem o limite diário de \(store.dailyFreeLimit) palavras.")
                        benefit("graduationcap.fill", "Treino sem parar", "Pratique quantas palavras quiser, todos os dias.")
                        benefit("bolt.heart.fill", "Compra única", "Pagamento único, sem assinatura. Vale para sempre.")
                        benefit("hand.thumbsup.fill", "Apoie o app", "Você ajuda a manter e melhorar o DerDieDas.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        Button {
                            Task {
                                if await purchase.purchase() { dismiss() }
                            }
                        } label: {
                            Group {
                                if purchase.isPurchasing {
                                    ProgressView()
                                } else if let product = purchase.proProduct {
                                    Text("Desbloquear • \(product.displayPrice)")
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Carregando…")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(purchase.proProduct == nil || purchase.isPurchasing)

                        Button("Restaurar Compras") {
                            Task {
                                await purchase.restore()
                                if purchase.isPro { dismiss() }
                            }
                        }
                        .font(.subheadline)

                        Text("Pagamento único. Sem assinatura.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let error = purchase.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("DerDieDas Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Agora não") { dismiss() }
                }
            }
            .onChange(of: purchase.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private func benefit(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseStore.shared)
        .environmentObject(AppStore.shared)
}
