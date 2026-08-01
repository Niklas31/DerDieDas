// Aba Buscar — porte de Artikel/Views/SearchView.swift.

import { searchCategorized } from '../search.js';
import { randomNoun } from '../data.js';
import { getHistory, registerSearch, getPrefs, setPref } from '../store.js';
import { el, badge, card, nounRow, section, clear } from '../ui.js';

const SEARCH_ICON =
  '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="10.5" cy="10.5" r="6.75" fill="none" stroke="currentColor" stroke-width="1.9"/><path d="M15.4 15.4 20.5 20.5" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"/></svg>';

let selectedNoun = null;

const input = el('input', {
  type: 'search',
  placeholder: 'Hund, cachorro, DER...',
  enterkeyhint: 'search',
  autocapitalize: 'off',
  autocorrect: 'off',
  autocomplete: 'off',
  spellcheck: 'false',
  'aria-label': 'Buscar substantivo',
});

const clearButton = el('button', {
  class: 'clear-button',
  type: 'button',
  text: '✕',
  'aria-label': 'Limpar busca',
});

const searchBar = el('div', { class: 'search-bar' }, [
  el('span', { html: SEARCH_ICON }),
  input,
  clearButton,
]);

const results = el('div');

const element = el('section', { class: 'view', id: 'view-search' }, [searchBar, results]);

function nounCard(noun) {
  const prefs = getPrefs();
  const showsTranslation = prefs.showTranslationInCard;

  const eye = el('button', {
    class: 'icon-button eye',
    type: 'button',
    'aria-label': showsTranslation ? 'Ocultar tradução' : 'Mostrar tradução',
    html: showsTranslation
      ? '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2.6 12S6.4 5.9 12 5.9 21.4 12 21.4 12 17.6 18.1 12 18.1 2.6 12 2.6 12z" fill="none" stroke="currentColor" stroke-width="1.7"/><circle cx="12" cy="12" r="2.9" fill="none" stroke="currentColor" stroke-width="1.7"/></svg>'
      : '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2.6 12S6.4 5.9 12 5.9c1.6 0 3 .5 4.3 1.2M21.4 12s-3.8 6.1-9.4 6.1c-1.7 0-3.2-.6-4.5-1.3" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M4 4l16 16" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
    onClick: () => {
      setPref('showTranslationInCard', !showsTranslation);
      render();
    },
  });

  const parts = [eye, badge(noun.article, 34), el('div', { class: 'word', text: noun.word })];

  if (showsTranslation) {
    parts.push(el('div', { class: 'label', text: 'Português:' }));
    parts.push(
      el('div', {
        class: 'translation',
        text: noun.translation || 'Sem tradução em português',
      })
    );
    if (noun.plural) {
      parts.push(el('div', { class: 'plural', text: `Plural: ${noun.plural}` }));
    }
  }

  return el('div', { class: 'noun-card' }, parts);
}

function selectNoun(noun) {
  selectedNoun = noun;
  registerSearch(noun);
  input.value = '';
  searchBar.classList.remove('has-text');
  render();
  // Refoco síncrono dentro do gesto: mantém o teclado aberto para a próxima busca.
  input.focus();
  window.scrollTo({ top: 0 });
}

function render() {
  clear(results);
  const query = input.value.trim();

  if (!query) {
    if (selectedNoun) results.append(nounCard(selectedNoun));

    const history = getHistory();
    if (history.length) {
      results.append(
        ...section('Histórico', card(history.map((item) => nounRow(item.noun, selectNoun))))
      );
    }
    return;
  }

  const { exact, partial } = searchCategorized(query);

  if (!exact.length && !partial.length) {
    results.append(
      el('div', { class: 'empty' }, [
        el('strong', { text: 'Nada encontrado' }),
        el('span', { text: `Nenhum substantivo corresponde a “${query}”.` }),
      ])
    );
    return;
  }

  if (exact.length) {
    results.append(
      ...section('Correspondência Exata', card(exact.map((noun) => nounRow(noun, selectNoun))))
    );
  }

  if (partial.length) {
    results.append(
      ...section(
        exact.length ? 'Outros Resultados' : 'Resultados',
        card(partial.map((noun) => nounRow(noun, selectNoun)))
      )
    );
  }
}

input.addEventListener('input', () => {
  searchBar.classList.toggle('has-text', input.value !== '');
  // Síncrono de propósito: varrer 12k itens custa poucos milissegundos e
  // requestAnimationFrame não dispara em abas que não estão pintando.
  render();
});

clearButton.addEventListener('click', () => {
  input.value = '';
  searchBar.classList.remove('has-text');
  render();
  input.focus();
});

input.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') event.preventDefault();
});

export function init() {
  selectedNoun = randomNoun();
  render();
}

export function onShow() {
  render();
}

export { element };
