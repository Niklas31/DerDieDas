// Porte de AppStore.searchCategorized (Artikel/Stores/AppStore.swift).

import { allNouns, normalize } from './data.js';

const RESULT_LIMIT = 300;

/**
 * Separa correspondências exatas (igualdade em palavra ou tradução) das parciais.
 * Busca por palavra, tradução, artigo ou plural — sem diferenciar maiúsculas nem acentos.
 * Query vazia devolve os primeiros 300 substantivos como "parciais", igual ao nativo.
 */
export function searchCategorized(query) {
  const nouns = allNouns();
  const trimmed = query.trim();

  if (!trimmed) {
    return { exact: [], partial: nouns.slice(0, RESULT_LIMIT) };
  }

  const q = normalize(trimmed);
  const exact = [];
  const partial = [];

  for (const noun of nouns) {
    const matches =
      noun.nWord.includes(q) ||
      noun.nTranslation.includes(q) ||
      noun.nArticle.includes(q) ||
      (noun.nPlural !== '' && noun.nPlural.includes(q));

    if (!matches) continue;

    if (noun.nWord === q || noun.nTranslation === q) {
      exact.push(noun);
    } else {
      partial.push(noun);
    }

    if (exact.length + partial.length >= RESULT_LIMIT) break;
  }

  return { exact, partial };
}
