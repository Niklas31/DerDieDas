// Service worker do DerDieDas — precache versionado, para o app funcionar offline.
//
// Estratégia: cache-first sobre uma lista fechada de arquivos, gravada de uma vez
// só sob uma chave de cache versionada. Como o conjunto inteiro entra e sai junto,
// nunca acontece de o index.html novo rodar com um módulo JS velho — o problema
// clássico de estratégias por arquivo.
//
// O bloco abaixo é GERADO. Rode `node tools/bump-sw.mjs` depois de mexer em
// qualquer arquivo de docs/ e antes de dar push, senão os aparelhos que já
// visitaram o site continuarão servindo a versão antiga do cache.

// <<<GENERATED>>>
const CACHE = 'ddd-b11796bde717';
const ASSETS = [
  './',
  './css/app.css',
  './data/GermanNouns.json',
  './icons/icon-180.png',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-512.png',
  './js/data.js',
  './js/format.js',
  './js/main.js',
  './js/pwa.js',
  './js/search.js',
  './js/store.js',
  './js/ui.js',
  './js/views/about.js',
  './js/views/history.js',
  './js/views/search.js',
  './js/views/stats.js',
  './js/views/training.js',
  './manifest.webmanifest',
  './privacidade.html',
];
// <<<END GENERATED>>>

/** Caminhos absolutos do precache, para casar com as requisições da página. */
const PRECACHED = new Set(ASSETS.map((path) => new URL(path, self.registration.scope).pathname));

const INDEX = new URL('./', self.registration.scope).pathname;

/**
 * Lê só do cache DESTA versão.
 *
 * `caches.match()` varre todos os caches da origem: enquanto um worker novo espera
 * o usuário aceitar a atualização, os dois caches coexistem e o worker antigo poderia
 * servir arquivos do cache novo — misturando versões, que é justamente o que este
 * desenho evita. Cada worker serve exclusivamente o que ele mesmo gravou.
 */
async function fromOwnCache(pathname) {
  const cache = await caches.open(CACHE);
  return cache.match(pathname);
}

/**
 * Baixa um arquivo furando o cache HTTP e o grava sob a URL limpa.
 *
 * `cache.addAll()` passa pelo cache HTTP do navegador — e o GitHub Pages serve os
 * arquivos com `max-age=600`. Nos 10 minutos seguintes a um deploy, o worker novo
 * gravaria cópias velhas de parte dos arquivos: exatamente o descasamento de versões
 * que o cache versionado existe para evitar. O `?v=` garante uma ida à rede em
 * qualquer navegador, inclusive onde a opção `cache` do fetch é ignorada.
 */
async function precache(cache, asset) {
  const response = await fetch(`${asset}${asset.includes('?') ? '&' : '?'}v=${CACHE}`, {
    cache: 'reload',
  });
  if (!response.ok) throw new Error(`precache falhou em ${asset}: ${response.status}`);
  await cache.put(asset, response);
}

self.addEventListener('install', (event) => {
  // Sem skipWaiting: o worker novo espera a página oferecer a atualização ao
  // usuário. Trocar sozinho recarregaria módulos no meio de um treino.
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      // Se um único arquivo falhar, a instalação inteira falha e o worker antigo
      // continua no ar — melhor uma versão velha inteira que uma nova pela metade.
      await Promise.all(ASSETS.map((asset) => precache(cache, asset)));
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names.filter((name) => name.startsWith('ddd-') && name !== CACHE).map((name) => caches.delete(name))
      );
      await self.clients.claim();
    })()
  );
});

self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
  // Usado para diagnosticar "está na versão certa?" sem devtools.
  if (event.data === 'VERSION') event.source?.postMessage({ version: CACHE });
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // Navegação (abrir o app, recarregar, voltar pelo histórico): a rede pode
  // estar fora, então o index.html do cache é sempre uma resposta válida.
  if (request.mode === 'navigate') {
    event.respondWith(
      (async () => {
        const cached = await fromOwnCache(PRECACHED.has(url.pathname) ? url.pathname : INDEX);
        if (cached) return cached;
        try {
          return await fetch(request);
        } catch {
          return (await fromOwnCache(INDEX)) ?? Response.error();
        }
      })()
    );
    return;
  }

  if (!PRECACHED.has(url.pathname)) return;

  event.respondWith(
    (async () => {
      const cached = await fromOwnCache(url.pathname);
      if (cached) return cached;
      // Só chega aqui se o cache foi esvaziado por fora (pressão de disco no iOS).
      const response = await fetch(request);
      if (response.ok) {
        const cache = await caches.open(CACHE);
        cache.put(url.pathname, response.clone());
      }
      return response;
    })()
  );
});
