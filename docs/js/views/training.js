// Aba Treino — porte de Artikel/Views/TrainingView.swift.
//
// Regra de ouro desta tela: o <input> do modo "Artigo -> Palavra" é criado UMA vez e
// nunca é removido do DOM. Ao avançar de palavra só trocamos texto e limpamos o valor,
// para que o teclado do iOS permaneça aberto durante todo o treino.

import { allNouns, randomNoun, nounForWord } from '../data.js';
import { recordPractice, getPrefs, setPref } from '../store.js';
import { el, badge, card, clear, reportLink } from '../ui.js';
import { render as renderStats } from './stats.js';

const ARTICLES = ['DER', 'DIE', 'DAS'];
const ADVANCE_DELAY = 800;

let currentNoun = null;
let advanceTimer = null;

// ------------------------------------------------------------------ controles

const modeSelect = el('select', { 'aria-label': 'Modo de treino' }, [
  el('option', { value: 'wordToArticle', text: 'Palavra -> Artigo' }),
  el('option', { value: 'articleToWord', text: 'Artigo -> Palavra' }),
]);

const translationToggle = el('input', { type: 'checkbox' });

const controls = card([
  el('div', { class: 'control-row' }, [el('span', { text: 'Modo' }), modeSelect]),
  el('div', { class: 'control-row' }, [
    el('span', { text: 'Mostrar tradução durante o treino' }),
    el('label', { class: 'switch' }, [translationToggle, el('span')]),
  ]),
]);

// ------------------------------------------------- modo A: palavra -> artigo

const wordLabel = el('div', { class: 'training-word' });
const translationBlock = el('div');

const articleButtons = el(
  'div',
  { class: 'article-buttons' },
  ARTICLES.map((article) =>
    el('button', {
      class: 'article-button',
      type: 'button',
      'data-article': article,
      text: article,
      onClick: () => submitArticle(article),
    })
  )
);

const modeA = el('div', { class: 'training-card' }, [wordLabel, translationBlock, articleButtons]);

// ------------------------------------------------- modo B: artigo -> palavra

const articleSlot = el('div');

const answerInput = el('input', {
  class: 'answer-field',
  type: 'text',
  enterkeyhint: 'go',
  autocapitalize: 'off',
  autocorrect: 'off',
  autocomplete: 'off',
  spellcheck: 'false',
  'aria-label': 'Sua resposta',
});

const answerButton = el('button', {
  class: 'article-button',
  type: 'button',
  text: 'Responder',
  style: 'background: var(--tint)',
  onClick: () => submitWord(),
});

const modeB = el('div', { class: 'training-card', hidden: true }, [
  articleSlot,
  el('div', {
    class: 'label',
    text: 'Digite qualquer substantivo do vocabulário que use este artigo.',
  }),
  answerInput,
  answerButton,
]);

answerInput.addEventListener('keydown', (event) => {
  if (event.key !== 'Enter') return;
  event.preventDefault();
  submitWord();
});

// --------------------------------------------------------------------- resto

const feedback = el('div', { class: 'feedback' });
const reportSlot = el('div', { style: 'text-align:center' });
const statsContainer = el('div');

const element = el('section', { class: 'view', id: 'view-training', hidden: true }, [
  controls,
  modeA,
  modeB,
  feedback,
  reportSlot,
  statsContainer,
]);

// ------------------------------------------------------------------- lógica

function exampleWord(article) {
  return allNouns().find((noun) => noun.article === article)?.word ?? 'palavra';
}

function renderTranslationBlock(noun) {
  clear(translationBlock);
  if (!getPrefs().showTranslationInTraining) return;

  translationBlock.append(
    el('div', { class: 'label', text: 'Tradução:' }),
    el('div', {
      class: 'translation',
      text: noun.translation || 'Sem tradução em português',
    })
  );
  if (noun.plural) {
    translationBlock.append(el('div', { class: 'plural', text: `Plural: ${noun.plural}` }));
  }
}

function renderCurrent() {
  if (!currentNoun) return;
  const mode = getPrefs().mode;

  modeA.hidden = mode !== 'wordToArticle';
  modeB.hidden = mode !== 'articleToWord';

  clear(reportSlot).append(reportLink(currentNoun));

  if (mode === 'wordToArticle') {
    wordLabel.textContent = currentNoun.word;
    renderTranslationBlock(currentNoun);
  } else {
    // Só troca o conteúdo do slot do artigo — o <input> abaixo permanece intacto.
    clear(articleSlot).append(badge(currentNoun.article, 34));
    answerInput.placeholder = `Ex.: ${exampleWord(currentNoun.article)}`;
  }
}

function setFeedback(text, kind) {
  feedback.textContent = text ?? '';
  feedback.className = `feedback${kind ? ` ${kind}` : ''}`;
}

function loadNextNoun(afterDelay = false) {
  clearTimeout(advanceTimer);
  const advance = () => {
    currentNoun = randomNoun();
    answerInput.value = '';
    setFeedback(null);
    renderCurrent();
    renderStats(statsContainer);
  };

  if (afterDelay) advanceTimer = setTimeout(advance, ADVANCE_DELAY);
  else advance();
}

function submitArticle(article) {
  if (!currentNoun) return;
  const isCorrect = article === currentNoun.article;
  recordPractice(currentNoun, isCorrect);
  setFeedback(isCorrect ? 'Correto' : `Era ${currentNoun.article}`, isCorrect ? 'correct' : 'wrong');
  loadNextNoun(true);
}

function submitWord() {
  if (!currentNoun) return;
  const answer = answerInput.value.trim();
  if (!answer) return;

  const match = nounForWord(answer);
  const isCorrect = match?.article === currentNoun.article;

  recordPractice(match ?? currentNoun, isCorrect);

  if (match) {
    setFeedback(
      isCorrect ? `Correto: ${match.article} ${match.word}` : `${match.word} usa ${match.article}`,
      isCorrect ? 'correct' : 'wrong'
    );
  } else {
    setFeedback('Palavra não encontrada no vocabulário', 'wrong');
  }

  // Limpa o valor sem tocar no nó: o teclado continua aberto para a próxima palavra.
  answerInput.value = '';
  loadNextNoun(true);
}

// ------------------------------------------------------------------- eventos

modeSelect.addEventListener('change', () => {
  setPref('mode', modeSelect.value);
  answerInput.value = '';
  setFeedback(null);
  renderCurrent();
});

translationToggle.addEventListener('change', () => {
  setPref('showTranslationInTraining', translationToggle.checked);
  renderCurrent();
});

export function init() {
  const prefs = getPrefs();
  modeSelect.value = prefs.mode;
  translationToggle.checked = prefs.showTranslationInTraining;
  loadNextNoun();
}

export function onShow() {
  if (!currentNoun) loadNextNoun();
  else renderStats(statsContainer);
}

export { element };
