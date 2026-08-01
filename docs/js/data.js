// Carrega e normaliza a base de substantivos.

export const ARTICLES = ['DER', 'DIE', 'DAS'];

/**
 * Normalização equivalente às opções [.caseInsensitive, .diacriticInsensitive] do Foundation.
 *
 * O `replace(/ß/g, 'ss')` é obrigatório: o .diacriticInsensitive do Foundation dobra ß em ss,
 * então sem isso "strasse" deixaria de encontrar "Straße" e a web divergiria do app nativo.
 */
export function normalize(text) {
  return text
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLowerCase()
    .replace(/ß/g, 'ss');
}

/** Chave de negócio que substitui o UUID do app nativo. */
export function keyFor(noun) {
  return `${noun.article}|${noun.word}`;
}

let nouns = [];
const byKey = new Map();
const byNormalizedWord = new Map();

export async function loadNouns() {
  const response = await fetch('./data/nouns.v1.json');
  if (!response.ok) throw new Error(`Falha ao carregar a base (HTTP ${response.status})`);

  const payload = await response.json();

  nouns = payload.rows.map(([articleIndex, word, translation, plural]) => {
    const article = ARTICLES[articleIndex];
    return {
      key: `${article}|${word}`,
      article,
      word,
      translation,
      plural,
      // pré-normalizados: a busca varre estes campos, nunca os originais
      nWord: normalize(word),
      nTranslation: normalize(translation),
      nPlural: plural ? normalize(plural) : '',
      nArticle: normalize(article),
    };
  });

  for (const noun of nouns) {
    byKey.set(noun.key, noun);
    // primeira ocorrência vence, como o `nouns.first { }` do Swift
    if (!byNormalizedWord.has(noun.nWord)) byNormalizedWord.set(noun.nWord, noun);
  }

  return nouns;
}

export function allNouns() {
  return nouns;
}

export function nounForKey(key) {
  return byKey.get(key);
}

/** Busca exata por palavra digitada — usada na validação do treino (O(1)). */
export function nounForWord(word) {
  return byNormalizedWord.get(normalize(word.trim()));
}

export function randomNoun() {
  return nouns[Math.floor(Math.random() * nouns.length)];
}
