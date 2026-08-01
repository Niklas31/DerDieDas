// Bloco de estatísticas — porte de Artikel/Views/StatisticsSummaryView.swift.

import { mostMissedWords, articleErrorStats, recentlyPracticed } from '../store.js';
import { formattedRelative, formatPercent } from '../format.js';
import { el, card, section, clear } from '../ui.js';

function statRow(label, value) {
  return el('div', { class: 'stat-row' }, [
    el('span', { text: label }),
    el('span', { class: 'value', text: value }),
  ]);
}

function block(title, rows, emptyText) {
  const content = rows.length
    ? card(rows)
    : card([el('div', { class: 'stat-row' }, [el('span', { class: 'value', text: emptyText })])]);
  return section(title, content);
}

export function render(container) {
  clear(container);

  container.append(
    ...block(
      'Palavras mais erradas',
      mostMissedWords()
        .slice(0, 5)
        .map((stat) => statRow(stat.noun.word, `${stat.wrongAttempts} erro(s)`)),
      'Sem erros registrados ainda.'
    )
  );

  container.append(
    ...section(
      'Artigos com maior índice de erro',
      card(
        articleErrorStats().map((stat) =>
          statRow(stat.article, stat.totalAttempts === 0 ? 'Sem dados' : formatPercent(stat.errorRate))
        )
      )
    )
  );

  container.append(
    ...block(
      'Última prática',
      recentlyPracticed()
        .slice(0, 5)
        .map((stat) => statRow(stat.noun.word, formattedRelative(stat.lastPracticedAt))),
      'Nenhuma palavra praticada ainda.'
    )
  );
}
