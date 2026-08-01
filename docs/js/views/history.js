// Aba Histórico — porte de Artikel/Views/HistoryView.swift.

import { getHistory } from '../store.js';
import { formattedRelative } from '../format.js';
import { el, card, empty, clear } from '../ui.js';

const list = el('div');
const element = el('section', { class: 'view', id: 'view-history', hidden: true }, [list]);

function historyRow({ noun, at }) {
  const parts = [
    el('div', { class: 'row-word', text: `${noun.article} • ${noun.word}` }),
    el('div', { class: 'row-sub', text: noun.translation || 'Sem tradução em português' }),
  ];

  if (noun.plural) {
    parts.push(el('div', { class: 'row-meta', text: `Plural: ${noun.plural}` }));
  }
  parts.push(el('div', { class: 'row-meta', text: formattedRelative(at) }));

  return el('div', { class: 'row' }, [el('span', { class: 'row-text' }, parts)]);
}

export function onShow() {
  clear(list);
  const history = getHistory();

  if (!history.length) {
    list.append(empty('Nenhuma busca ainda', 'As palavras buscadas aparecerão aqui.'));
    return;
  }

  list.append(card(history.map(historyRow)));
}

export { element };
