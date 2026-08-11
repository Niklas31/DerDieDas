#!/usr/bin/env node
// Regera a lista de arquivos e a versão do cache em docs/sw.js.
//
// O maior risco de um PWA com cache-first é publicar código novo e esquecer de
// trocar a versão do cache: quem já visitou o site fica preso na versão antiga
// para sempre, sem jeito de consertar remotamente. Por isso a versão não é
// escrita à mão — é o hash do conteúdo de todos os arquivos publicados. Mudou
// um byte em qualquer lugar, muda a versão.
//
// Uso:  node tools/bump-sw.mjs
// Rode sempre depois de mexer em docs/ e antes do push.

import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const docs = join(root, 'docs');
const swPath = join(docs, 'sw.js');

/** Arquivos que o app precisa para rodar. O sw.js não entra: ele é o cache, não o conteúdo. */
const INCLUDED = /\.(html|css|js|json|webmanifest|png|svg|woff2)$/;
const EXCLUDED = new Set(['sw.js']);

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    if (name.startsWith('.')) return [];
    const full = join(dir, name);
    if (statSync(full).isDirectory()) return walk(full);
    const rel = relative(docs, full);
    if (EXCLUDED.has(rel) || !INCLUDED.test(name)) return [];
    return [rel];
  });
}

const files = walk(docs).sort();

/**
 * Os pacotes de idioma ficam **fora** do precache.
 *
 * O install é atômico — `Promise.all` sobre a lista inteira — e é isso que garante que o
 * app entra e sai do cache de uma vez. Se cada idioma novo entrasse na lista, o usuário
 * baixaria cinco pacotes para usar um, e uma única falha abortaria a instalação inteira.
 * Eles são cacheados no primeiro uso, por `sw.js`.
 */
const isPack = (file) => file.startsWith('data/lang/');

const core = files.filter((file) => !isPack(file));
const packs = files.filter(isPack);

// index.html é referenciado como './' — é assim que o navegador pede a página.
const assets = core.map((file) => (file === 'index.html' ? './' : `./${file}`)).sort();

const source = readFileSync(swPath, 'utf8');
const pattern = /\/\/ <<<GENERATED>>>[\s\S]*?\/\/ <<<END GENERATED>>>/;
if (!pattern.test(source)) {
  console.error('docs/sw.js perdeu os marcadores <<<GENERATED>>>; nada foi alterado.');
  process.exit(1);
}

const hash = createHash('sha256');
for (const file of files) {
  hash.update(file);
  hash.update(readFileSync(join(docs, file)));
}
// O próprio sw.js entra no hash, senão mudar a lógica de cache não invalidaria o
// cache. Entra sem o bloco gerado — que contém a versão —, para não se morder.
hash.update(source.replace(pattern, ''));

const version = `ddd-${hash.digest('hex').slice(0, 12)}`;

/** Hash de cada pacote isolado: é a chave de cache dele, e muda só quando ele muda. */
const packHashes = packs.map((file) => {
  const hash = createHash('sha256').update(readFileSync(join(docs, file))).digest('hex');
  return [`./${file}`, hash.slice(0, 12)];
});

const block = [
  '// <<<GENERATED>>>',
  `const CACHE = '${version}';`,
  'const ASSETS = [',
  ...assets.map((asset) => `  '${asset}',`),
  '];',
  '// Pacotes de idioma: fora do precache, cacheados sob demanda e versionados um a um,',
  '// para que um deploy não apague a tradução de quem está offline.',
  'const PACKS = {',
  ...packHashes.map(([path, hash]) => `  '${path}': '${hash}',`),
  '};',
  '// <<<END GENERATED>>>',
].join('\n');

const previous = source.match(/const CACHE = '([^']+)'/)?.[1];
writeFileSync(swPath, source.replace(pattern, block));

console.log(`${assets.length} arquivos no precache`);
console.log(`${packHashes.length} pacotes de idioma sob demanda: ${packHashes.map(([p]) => p.split('/').pop()).join(', ') || '(nenhum)'}`);
console.log(previous === version ? `versão inalterada: ${version}` : `${previous} → ${version}`);
