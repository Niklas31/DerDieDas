#!/bin/bash
# Verifica que Swift e JavaScript resolvem o idioma **igual**.
#
# As duas implementações são independentes por necessidade — uma roda no iPhone, a outra
# no navegador — e uma divergência entre elas não aparece em lugar nenhum: o app mostra
# inglês, o site mostra português, e ninguém percebe até um usuário reclamar. Esta
# verificação lê a mesma tabela nos dois e compara.
#
# Roda fora do Xcode de propósito: `swiftc` compila o próprio arquivo do app, sem cópia,
# então não existe a possibilidade de testar uma versão que não é a que vai para o
# aparelho. O arquivo de teste precisa se chamar `main.swift` — é o único nome em que o
# compilador aceita código no nível de topo.
#
# Uso:  tools/check-language.sh
set -euo pipefail
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.swift" <<'SWIFT'
import Foundation

struct Caso: Decodable {
    let porque: String
    let override: String?
    let preferred: [String]
    let esperado: String
}
struct Tabela: Decodable { let cases: [Caso] }

let dados = try Data(contentsOf: URL(fileURLWithPath: "tools/language-cases.json"))
let tabela = try JSONDecoder().decode(Tabela.self, from: dados)

var falhas = 0
for caso in tabela.cases {
    let obtido = TranslationLanguage.resolve(override: caso.override, preferred: caso.preferred).rawValue
    if obtido != caso.esperado {
        falhas += 1
        print("  swift FALHOU: \(caso.porque)")
        print("    override=\(caso.override.map { "\"\($0)\"" } ?? "nil") preferred=\(caso.preferred)")
        print("    esperado \(caso.esperado), obtido \(obtido)")
    }
}
print("swift: \(tabela.cases.count - falhas)/\(tabela.cases.count)")
exit(falhas == 0 ? 0 : 1)
SWIFT

cat > "$TMP/main.mjs" <<'JS'
import { readFileSync } from 'node:fs';
import { resolve } from '../docs/js/locale.js';

const tabela = JSON.parse(readFileSync('tools/language-cases.json', 'utf8'));
let falhas = 0;
for (const caso of tabela.cases) {
  const obtido = resolve(caso.override, caso.preferred);
  if (obtido !== caso.esperado) {
    falhas += 1;
    console.log(`  js FALHOU: ${caso.porque}`);
    console.log(`    override=${JSON.stringify(caso.override)} preferred=${JSON.stringify(caso.preferred)}`);
    console.log(`    esperado ${caso.esperado}, obtido ${obtido}`);
  }
}
console.log(`js:    ${tabela.cases.length - falhas}/${tabela.cases.length}`);
process.exit(falhas === 0 ? 0 : 1);
JS

# O .mjs precisa ficar dentro do repositório para o import relativo de docs/js/ funcionar.
cp "$TMP/main.mjs" tools/.check-language.mjs
trap 'rm -rf "$TMP"; rm -f tools/.check-language.mjs' EXIT

estado=0
swiftc -O "Artikel/Models/TranslationLanguage.swift" "$TMP/main.swift" -o "$TMP/langcheck"
"$TMP/langcheck" || estado=1
node tools/.check-language.mjs || estado=1

if [ $estado -eq 0 ]; then
    echo "As duas implementações concordam."
else
    echo "DIVERGÊNCIA — corrija antes de seguir."
fi
exit $estado
