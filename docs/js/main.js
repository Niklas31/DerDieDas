// Bootstrap e navegação entre abas.

import { loadNouns } from './data.js';
import { setupPWA } from './pwa.js';
import * as search from './views/search.js';
import * as historyView from './views/history.js';
import * as training from './views/training.js';
import * as about from './views/about.js';

const TITLES = {
  search: 'Buscar',
  history: 'Histórico',
  training: 'Treino',
  about: 'Sobre',
};

const views = { search, history: historyView, training, about };

const container = document.getElementById('view-container');
const title = document.getElementById('view-title');
const aboutButton = document.getElementById('about-button');
const loading = document.getElementById('loading');
const tabs = [...document.querySelectorAll('.tab')];

let currentTab = 'search';

function show(name) {
  for (const [key, view] of Object.entries(views)) {
    view.element.hidden = key !== name;
  }

  title.textContent = TITLES[name];
  views[name].onShow?.();

  // O botão "Sobre" vive na aba Treino, como no app nativo.
  aboutButton.hidden = name !== 'training' && name !== 'about';
  aboutButton.setAttribute('aria-label', name === 'about' ? 'Fechar' : 'Sobre e créditos');

  for (const tab of tabs) {
    const selected = tab.dataset.tab === (name === 'about' ? 'training' : name);
    tab.setAttribute('aria-selected', String(selected));
  }

  if (name !== 'about') currentTab = name;
  if (location.hash !== `#${name}`) window.history.replaceState(null, '', `#${name}`);
  window.scrollTo({ top: 0 });
}

for (const tab of tabs) {
  tab.addEventListener('click', () => show(tab.dataset.tab));
}

aboutButton.addEventListener('click', () => {
  show(views.about.element.hidden ? 'about' : currentTab);
});

window.addEventListener('hashchange', () => {
  const name = location.hash.slice(1);
  if (views[name]) show(name);
});

async function start() {
  // Antes de carregar os dados: se a base falhar, é justamente o service worker
  // que precisa estar de pé para servi-la do cache na próxima abertura.
  setupPWA();

  try {
    await loadNouns();
  } catch (error) {
    loading.textContent = 'Não foi possível carregar a base de substantivos.';
    console.error(error);
    return;
  }

  container.append(search.element, historyView.element, training.element, about.element);

  search.init();
  training.init();

  const initial = location.hash.slice(1);
  show(views[initial] ? initial : 'search');

  loading.hidden = true;
}

start();
