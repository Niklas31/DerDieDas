#!/usr/bin/env node
// Gera docs/data/nouns.v1.json a partir de Artikel/GermanNouns.json.
//
// O JSON do app iOS é a fonte única de verdade. Este script só o compacta para a web:
// remove o campo `id` (UUID inútil no navegador, ~32% do payload), troca objetos por
// linhas (sem repetir as chaves 12 mil vezes), deduplica e ordena.
//
// Uso: node tools/build-web-data.mjs

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const SRC = join(root, 'Artikel/GermanNouns.json');
const OUT = join(root, 'docs/data/nouns.v1.json');

const ARTICLES = ['DER', 'DIE', 'DAS'];

const source = JSON.parse(readFileSync(SRC, 'utf8'));
console.log(`Lidos ${source.length} substantivos de Artikel/GermanNouns.json`);

// Deduplica por ARTICLE|word — a chave de negócio usada no localStorage.
// A base tem uma colisão real: "DIE Auktion" aparece duas vezes com ids diferentes.
const seen = new Map();
const duplicates = [];
for (const item of source) {
  if (!item.word || !item.article) continue;
  const key = `${item.article}|${item.word}`;
  if (seen.has(key)) {
    duplicates.push(key);
    continue;
  }
  seen.set(key, item);
}
if (duplicates.length) {
  console.log(`Duplicatas removidas (${duplicates.length}): ${duplicates.join(', ')}`);
}

// Mesma ordenação do app iOS (AppStore.loadBundledNouns usa localizedCaseInsensitiveCompare).
const collator = new Intl.Collator('de', { sensitivity: 'base' });
const rows = [...seen.values()]
  .sort((a, b) => collator.compare(a.word, b.word))
  .map((item) => {
    const articleIndex = ARTICLES.indexOf(item.article);
    if (articleIndex < 0) throw new Error(`Artigo desconhecido: ${item.article} (${item.word})`);
    return [articleIndex, item.word, item.portugueseTranslation ?? '', item.plural ?? null];
  });

mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(OUT, JSON.stringify({ v: 1, rows }), 'utf8');

const bytes = readFileSync(OUT).length;
const counts = rows.reduce((acc, r) => ((acc[ARTICLES[r[0]]] = (acc[ARTICLES[r[0]]] ?? 0) + 1), acc), {});

console.log(`\nGravado docs/data/nouns.v1.json`);
console.log(`  ${rows.length} substantivos · ${(bytes / 1024).toFixed(0)} KB`);
console.log(`  DER ${counts.DER} · DIE ${counts.DIE} · DAS ${counts.DAS}`);
console.log(`  primeiro: ${ARTICLES[rows[0][0]]} ${rows[0][1]} · último: ${ARTICLES[rows.at(-1)[0]]} ${rows.at(-1)[1]}`);
