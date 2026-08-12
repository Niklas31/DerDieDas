import SwiftUI

struct CreditsView: View {
    @EnvironmentObject private var purchase: PurchaseStore
    @Environment(\.dismiss) private var dismiss
    @State private var showsPaywall = false

    // Ajuste para a URL pública da sua política de privacidade (ex.: GitHub Pages).
    private let privacyPolicyURL = URL(string: "https://derdiedas.app.br/privacidade.html")

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text("DerDieDas")
                            .font(.title2.weight(.semibold))
                        Text("Versão \(appVersion)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("DerDieDas Pro") {
                    if purchase.isPro {
                        Label("Pro ativo — obrigado pelo apoio!", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            showsPaywall = true
                        } label: {
                            Label("Desbloquear palavras ilimitadas", systemImage: "star.fill")
                        }
                        Button("Restaurar Compras") {
                            Task { await purchase.restore() }
                        }
                    }
                }

                Section("Sobre") {
                    Text("Aprender alemão tem um obstáculo que quase todo brasileiro conhece: decorar se cada substantivo é der, die ou das. Não existe atalho fácil — e foi para atacar exatamente essa dificuldade que o DerDieDas nasceu.\n\nEm vez de jogar você contra um dicionário gigante cheio de termos técnicos e palavras raras, o app oferece uma seleção curada de substantivos realmente úteis do cotidiano (níveis A1 a B1), cada um com artigo, tradução e plural. A tradução pode ser em português ou em inglês — a escolha fica na aba Treino, e no automático o app segue o idioma do aparelho. Treinando o vocabulário certo, você também começa a enxergar os padrões escondidos da língua: palavras terminadas em -ung são sempre die, as em -chen são das, infinitivos substantivados são das, e por aí vai.\n\nCom busca instantânea, dois modos de treino, histórico e estatísticas dos seus erros, o DerDieDas foi feito para caber na sua rotina e transformar a parte mais espinhosa do alemão em prática rápida — e sem frustração.")
                        .font(.subheadline)
                }

                Section("Como foi feito") {
                    Text("O ponto de partida foi a lista aberta german-nouns, compilada do Wikcionário alemão (WiktionaryDE): mais de 90 mil substantivos com artigo e plural — a maioria composta por termos químicos, moedas antigas e palavras raríssimas que ninguém usa no dia a dia.")
                        .font(.subheadline)

                    Text("Num script em Python (Google Colab), essa lista passou por um filtro de frequência de uso com a biblioteca wordfreq: só permaneceram as palavras que aparecem pelo menos cerca de 1 vez por milhão no alemão real — o corte de 1e-6 (0,0001%). Isso derruba automaticamente a cauda longa de termos raros. Uma segunda passada ainda removeu duplicatas, abreviações e verbos infiltrados.")
                        .font(.subheadline)

                    Text("As traduções para o português começaram no Google Tradutor e passaram por uma revisão manual, que removeu nomes próprios, marcas e siglas e consertou os erros de desambiguação — der Rock é saia, não pedra; das Tag é etiqueta, não dia. Um tradutor automático não tem como acertar isso, porque decide sem saber o artigo.")
                        .font(.subheadline)

                    Text("O pacote em inglês veio depois, gerado com o Claude, da Anthropic, recebendo o artigo e o plural junto com cada palavra — é justamente esse contexto que separa Röcke (saias) de Rocks (o gênero musical). Cada pacote é conferido por um script que compara as duas versões e sinaliza traduções suspeitas para revisão.")
                        .font(.subheadline)

                    Text("Achou algum erro? Use o botão de reportar — as correções entram nas próximas versões.")
                        .font(.subheadline)
                }

                Section("Ferramentas") {
                    creditRow(title: "Base de dados", detail: "german-nouns · WiktionaryDE")
                    creditRow(title: "Filtro de frequência", detail: "wordfreq · corte 1e-6")
                    creditRow(title: "Tradução em português", detail: "Google Tradutor · revisão manual")
                    creditRow(title: "Tradução em inglês", detail: "Claude · Anthropic")
                    creditRow(title: "Scripts", detail: "Google Gemini · Colab")
                    creditRow(title: "Tradução no dispositivo", detail: "Apple Translation")
                    creditRow(title: "Desenvolvimento", detail: "SwiftUI · iOS e watchOS")
                }

                Section("Créditos & Licenças") {
                    // As traduções não vêm do german-nouns e não herdam a CC BY-SA — dizer
                    // de onde cada parte veio é o que mantém a atribuição correta.
                    Text("A base de artigos e plurais vem do projeto aberto german-nouns, compilado do WiktionaryDE e publicado sob a licença Creative Commons Atribuição-CompartilhaIgual 4.0 (CC BY-SA 4.0). As traduções não fazem parte dessa base: as em português vieram do Google Tradutor com revisão manual, e as em inglês foram geradas com o Claude, da Anthropic.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Link(destination: URL(string: "https://github.com/gambolputty/german-nouns")!) {
                        Label("Projeto german-nouns", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Link(destination: URL(string: "https://de.wiktionary.org")!) {
                        Label("WiktionaryDE", systemImage: "book")
                    }
                    Link(destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/deed.pt_BR")!) {
                        Label("Licença CC BY-SA 4.0", systemImage: "doc.text")
                    }
                }

                Section("Tradução") {
                    Text("Palavras fora da base curada podem ser traduzidas sob demanda pelo framework de tradução nativo da Apple, processado no próprio dispositivo. Requer iOS 18 ou superior.")
                        .font(.subheadline)
                }

                if let privacyPolicyURL {
                    Section("Privacidade") {
                        Link(destination: privacyPolicyURL) {
                            Label("Política de Privacidade", systemImage: "hand.raised")
                        }
                    }
                }
            }
            .navigationTitle("Sobre")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showsPaywall) {
                PaywallView()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluído") { dismiss() }
                }
            }
        }
    }

    private func creditRow(title: String, detail: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

#Preview {
    CreditsView()
        .environmentObject(PurchaseStore.shared)
}
