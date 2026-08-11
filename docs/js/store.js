// Persistência local — porte do AppStore (UserDefaults -> localStorage).
//
// O prefixo `ddd.` é obrigatório: niklas31.github.io é uma origem compartilhada
// com todos os outros repositórios publicados no GitHub Pages.

import { ARTICLES, keyFor, nounForKey } from './data.js';
import { match } from './locale.js';

const PREFIX = 'ddd.';
const HISTORY_LIMIT = 50;

// A versão web é gratuita e ilimitada. Trocar por um número religa o limite diário.
export const FREE_LIMIT = Infinity;

const DEFAULT_PREFS = {
  mode: 'wordToArticle',
  showTranslationInTraining: false,
  showTranslationInCard: true,
  // `null` = seguir o navegador. Só a escolha explícita é gravada; o idioma resolvido
  // nunca, senão a preferência congela no primeiro acesso e trocar o idioma do navegador
  // depois não muda mais nada.
  translationLang: null,
};

function read(key, fallback) {
  try {
    const raw = localStorage.getItem(PREFIX + key);
    return raw === null ? fallback : JSON.parse(raw);
  } catch {
    return fallback;
  }
}

// localStorage é síncrono e bloqueia a main thread; agrupamos as escritas.
const pendingWrites = new Map();
let flushTimer = null;

function write(key, value) {
  pendingWrites.set(key, value);
  if (flushTimer !== null) return;
  flushTimer = setTimeout(() => {
    flushTimer = null;
    for (const [k, v] of pendingWrites) {
      try {
        localStorage.setItem(PREFIX + k, JSON.stringify(v));
      } catch {
        // cota estourada ou modo privado: seguimos sem persistir
      }
    }
    pendingWrites.clear();
  }, 50);
}

let history = read('history', []);
let stats = read('stats', {});
let prefs = { ...DEFAULT_PREFS, ...read('prefs', {}) };

write('schema', 1);

// ---------------------------------------------------------------- preferências

export function getPrefs() {
  return prefs;
}

export function setPref(key, value) {
  prefs = { ...prefs, [key]: value };
  write('prefs', prefs);
}

// ------------------------------------------------------------------ histórico

/** Itens do histórico resolvidos contra a base atual (mais recente primeiro). */
export function getHistory() {
  return history
    .map((entry) => ({ noun: nounForKey(entry.k), at: entry.at }))
    .filter((entry) => entry.noun);
}

export function registerSearch(noun) {
  history = [{ k: keyFor(noun), at: Date.now() }, ...history].slice(0, HISTORY_LIMIT);
  write('history', history);
}

// ----------------------------------------------------------------- estatísticas

export function recordPractice(noun, isCorrect) {
  const key = keyFor(noun);
  const current = stats[key] ?? { t: 0, w: 0, l: null };
  stats[key] = {
    t: current.t + 1,
    w: current.w + (isCorrect ? 0 : 1),
    l: Date.now(),
  };
  write('stats', stats);
}

function statEntries() {
  return Object.entries(stats)
    .map(([key, value]) => {
      const noun = nounForKey(key);
      if (!noun) return null;
      return {
        noun,
        totalAttempts: value.t,
        wrongAttempts: value.w,
        lastPracticedAt: value.l,
        errorRate: value.t > 0 ? value.w / value.t : 0,
      };
    })
    .filter(Boolean);
}

/** Mais erradas primeiro; empate desfeito pela taxa de erro (igual ao Swift). */
export function mostMissedWords() {
  return statEntries()
    .filter((entry) => entry.wrongAttempts > 0)
    .sort((a, b) =>
      a.wrongAttempts === b.wrongAttempts
        ? b.errorRate - a.errorRate
        : b.wrongAttempts - a.wrongAttempts
    );
}

/** Sempre as três linhas DER/DIE/DAS, ordenadas por taxa de erro. */
export function articleErrorStats() {
  const entries = statEntries();
  return ARTICLES.map((article) => {
    const matching = entries.filter((entry) => entry.noun.article === article);
    const totalAttempts = matching.reduce((sum, entry) => sum + entry.totalAttempts, 0);
    const wrongAttempts = matching.reduce((sum, entry) => sum + entry.wrongAttempts, 0);
    return {
      article,
      totalAttempts,
      wrongAttempts,
      errorRate: totalAttempts > 0 ? wrongAttempts / totalAttempts : 0,
    };
  }).sort((a, b) => b.errorRate - a.errorRate);
}

export function recentlyPracticed() {
  return statEntries()
    .filter((entry) => entry.lastPracticedAt)
    .sort((a, b) => b.lastPracticedAt - a.lastPracticedAt);
}

// ------------------------------------------------------------ backup (Sobre)

export function exportData() {
  return JSON.stringify({ schema: 1, history, stats, prefs }, null, 2);
}

export function importData(json) {
  const parsed = JSON.parse(json);
  if (Array.isArray(parsed.history)) {
    history = parsed.history.slice(0, HISTORY_LIMIT);
    write('history', history);
  }
  if (parsed.stats && typeof parsed.stats === 'object') {
    stats = parsed.stats;
    write('stats', stats);
  }
  if (parsed.prefs && typeof parsed.prefs === 'object') {
    prefs = { ...DEFAULT_PREFS, ...parsed.prefs };
    // Um idioma que não existe mais — export antigo, ou pacote retirado — vira ausência
    // de escolha em vez de escolha impossível, e o app volta a seguir o navegador.
    if (prefs.translationLang && !match(prefs.translationLang)) {
      prefs.translationLang = null;
    }
    write('prefs', prefs);
  }
}
