// Resolução do idioma da tradução — porte de Artikel/Models/TranslationLanguage.swift.
//
// Este arquivo e o Swift precisam decidir **igual**. Uma divergência aqui é invisível: o
// app e o site simplesmente mostram idiomas diferentes para a mesma pessoa, e ninguém
// descobre até um usuário reclamar. Por isso os dois são verificados contra a mesma
// tabela, `tools/language-cases.json`, por `tools/check-language.sh`.
//
// Ao mexer em qualquer regra daqui, mexa no Swift e rode a verificação.

export const LANGUAGES = [
  { code: 'pt-BR', label: 'Português (Brasil)' },
  { code: 'en', label: 'English' },
];

/** Inglês, e não português — veja o porquê no Swift. */
export const FALLBACK = 'en';

const CODES = LANGUAGES.map((l) => l.code);

/** Casa uma etiqueta BCP-47 com um pacote, colapsando região. */
export function match(tag) {
  if (!tag) return null;
  const normalized = String(tag).toLowerCase().replace(/_/g, '-');
  const exato = CODES.find((code) => code.toLowerCase() === normalized);
  if (exato) return exato;

  const base = normalized.split('-')[0];
  if (base === 'pt') return 'pt-BR';
  if (base === 'en') return 'en';
  return null;
}

/**
 * Escolha explícita, senão o navegador, senão o padrão.
 *
 * `override` é `null` enquanto a pessoa não escolher — e é isso que faz o site seguir o
 * navegador. O valor resolvido **não** é gravado: gravá-lo congelaria a escolha no
 * primeiro acesso, e trocar o idioma do navegador depois não mudaria mais nada.
 */
export function resolve(override, preferred) {
  if (override) {
    const escolhido = match(override);
    if (escolhido) return escolhido;
  }
  for (const tag of preferred ?? []) {
    const encontrado = match(tag);
    if (encontrado) return encontrado;
  }
  return FALLBACK;
}

/** As etiquetas do navegador, em ordem de preferência. */
export function browserLanguages() {
  if (typeof navigator === 'undefined') return [];
  return navigator.languages?.length ? [...navigator.languages] : [navigator.language].filter(Boolean);
}
