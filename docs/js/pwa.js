// Registro do service worker, aviso de atualização e convite para instalar.

import { el } from './ui.js';

const DISMISSED_KEY = 'ddd.installHintDismissed';

/** Rodando como app instalado (tela de início do iOS ou PWA no Android/desktop). */
export function isInstalled() {
  return window.navigator.standalone === true
    || window.matchMedia('(display-mode: standalone)').matches;
}

function isIOS() {
  const ua = navigator.userAgent;
  // iPadOS se apresenta como Mac; o que o denuncia é ter touch.
  return /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1);
}

// ------------------------------------------------------------------ barra inferior

function bar(className, children) {
  const node = el('div', { class: `pwa-bar ${className}` }, children);
  document.body.append(node);
  // Deixa o browser pintar o estado inicial antes de animar a entrada.
  requestAnimationFrame(() => node.classList.add('visible'));
  return node;
}

function dismiss(node) {
  node.classList.remove('visible');
  node.addEventListener('transitionend', () => node.remove(), { once: true });
}

// ------------------------------------------------------------------ atualização

function offerUpdate(worker) {
  let reloading = false;

  // O controlador só troca depois que o worker novo assume; recarregar antes
  // disso serviria de novo os arquivos velhos.
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (reloading) return;
    reloading = true;
    location.reload();
  });

  const node = bar('pwa-update', [
    el('span', { class: 'pwa-text', text: 'Nova versão disponível.' }),
    el('button', {
      class: 'pwa-action',
      type: 'button',
      text: 'Atualizar',
      onClick: () => {
        node.querySelector('.pwa-text').textContent = 'Atualizando…';
        worker.postMessage('SKIP_WAITING');
      },
    }),
    el('button', {
      class: 'pwa-close',
      type: 'button',
      'aria-label': 'Agora não',
      text: '✕',
      onClick: () => dismiss(node),
    }),
  ]);
}

// ------------------------------------------------------------------ instalação

function offerInstall(prompt) {
  if (localStorage.getItem(DISMISSED_KEY) === '1') return;

  const close = () => {
    localStorage.setItem(DISMISSED_KEY, '1');
    dismiss(node);
  };

  const action = prompt
    ? el('button', {
        class: 'pwa-action',
        type: 'button',
        text: 'Instalar',
        onClick: async () => {
          prompt.prompt();
          await prompt.userChoice;
          close();
        },
      })
    : null;

  const text = prompt
    ? 'Instale o DerDieDas para usar offline.'
    : 'Para usar offline, toque em Compartilhar e escolha “Adicionar à Tela de Início”.';

  const node = bar('pwa-install', [
    el('img', { class: 'pwa-icon', src: './icons/icon-192.png', alt: '' }),
    el('span', { class: 'pwa-text', text }),
    action,
    el('button', {
      class: 'pwa-close',
      type: 'button',
      'aria-label': 'Dispensar',
      text: '✕',
      onClick: close,
    }),
  ]);
}

// ------------------------------------------------------------------ bootstrap

export function setupPWA() {
  // Android e desktop avisam quando dá para instalar; o iOS nunca dispara isto.
  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    if (!isInstalled()) offerInstall(event);
  });

  // No iOS o convite é a única forma de o usuário descobrir o gesto — e é o que
  // protege os dados: fora da tela de início o Safari apaga o localStorage
  // depois de 7 dias sem uso.
  if (isIOS() && !isInstalled()) {
    setTimeout(() => offerInstall(null), 4000);
  }

  if (!('serviceWorker' in navigator)) return;

  window.addEventListener('load', async () => {
    let registration;
    try {
      registration = await navigator.serviceWorker.register('./sw.js');
    } catch (error) {
      console.error('service worker não registrou', error);
      return;
    }

    // Já havia um worker novo esperando de uma visita anterior.
    if (registration.waiting && navigator.serviceWorker.controller) {
      offerUpdate(registration.waiting);
    }

    registration.addEventListener('updatefound', () => {
      const installing = registration.installing;
      if (!installing) return;
      installing.addEventListener('statechange', () => {
        // Sem controller é a primeira visita: instalou, não atualizou.
        if (installing.state === 'installed' && navigator.serviceWorker.controller) {
          offerUpdate(installing);
        }
      });
    });

    // Instalado, o app pode ficar aberto por dias sem nunca recarregar; sem isto
    // ele só procuraria atualização no próximo boot.
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') registration.update();
    });
  });
}
