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
let baseDigest = '';
let currentLanguage = '';
const byKey = new Map();
const byNormalizedWord = new Map();

/**
 * Carrega os fatos do alemão. Falhar aqui é fatal — sem base não há app.
 *
 * Mesmo arquivo que os apps iOS e watchOS empacotam: fonte única, sem duplicata.
 */
export async function loadBase() {
  const response = await fetch('./data/GermanNouns.json');
  if (!response.ok) throw new Error(`Falha ao carregar a base (HTTP ${response.status})`);

  const payload = await response.json();
  if (!Array.isArray(payload.nouns) || payload.nouns.length !== payload.count) {
    throw new Error('Base com contagem inconsistente');
  }
  baseDigest = payload.digest;

  nouns = payload.nouns.map(({ article, word, plural }) => ({
    key: `${article}|${word}`,
    article,
    word,
    plural,
    translation: '',
    // pré-normalizados: a busca varre estes campos, nunca os originais
    nWord: normalize(word),
    nTranslation: '',
    nPlural: plural ? normalize(plural) : '',
    nArticle: normalize(article),
  }));

  byKey.clear();
  byNormalizedWord.clear();
  for (const noun of nouns) {
    byKey.set(noun.key, noun);
    // primeira ocorrência vence, como o `nouns.first { }` do Swift
    if (!byNormalizedWord.has(noun.nWord)) byNormalizedWord.set(noun.nWord, noun);
  }

  return nouns;
}

/**
 * Aplica um pacote de tradução por índice — ou nenhum.
 *
 * O pacote é um array alinhado à ordem da base, o que custa metade do tamanho de um mapa
 * chaveado. O preço é depender da ordem, então `digest` e `count` são conferidos antes:
 * um pacote fora de sincronia é descartado **inteiro**. Aplicar pela metade daria a
 * palavra a tradução da vizinha — parece certo e ensina errado.
 *
 * Falhar aqui **não** é fatal: sem tradução o app ainda ensina artigo e plural.
 */
export async function loadPack(language) {
  try {
    const response = await fetch(`./data/lang/${language}.json`);
    if (!response.ok) return false;

    const pack = await response.json();
    if (pack.digest !== baseDigest || pack.translations?.length !== nouns.length) {
      console.warn(`pacote ${language} fora de sincronia com a base — descartado`);
      return false;
    }

    nouns.forEach((noun, index) => {
      noun.translation = pack.translations[index];
      noun.nTranslation = noun.translation ? normalize(noun.translation) : '';
    });
    currentLanguage = language;
    return true;
  } catch (error) {
    console.warn(`pacote ${language} indisponível`, error);
    return false;
  }
}

export function activeLanguage() {
  return currentLanguage;
}

/**
 * Garante que o pacote ativo esteja no cache do service worker.
 *
 * Na primeira visita o worker ainda não controla a página quando `loadPack` roda, então
 * aquele fetch passa direto pela rede e não é guardado. Quem instalasse o app e ficasse
 * offline em seguida veria a base sem tradução. Este pedido extra acontece só uma vez —
 * depois é acerto de cache e não custa nada.
 */
export async function warmPack(language = currentLanguage) {
  if (!language || !('serviceWorker' in navigator)) return;
  try {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) return;
    await fetch(`./data/lang/${language}.json`);
  } catch {
    // Sem rede não há o que aquecer; o app segue com o que já tem.
  }
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
