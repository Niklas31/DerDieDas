// Componentes compartilhados.

export function el(tag, props = {}, children = []) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(props)) {
    if (key === 'class') node.className = value;
    else if (key === 'text') node.textContent = value;
    else if (key === 'html') node.innerHTML = value;
    else if (key.startsWith('on')) node.addEventListener(key.slice(2).toLowerCase(), value);
    else if (value !== null && value !== false) node.setAttribute(key, value === true ? '' : value);
  }
  for (const child of [].concat(children)) {
    if (child) node.append(child);
  }
  return node;
}

/**
 * Equivalente ao ArticleBadge.swift: retângulo de raio 8, texto branco,
 * peso black, com padding proporcional ao tamanho da fonte.
 */
export function badge(article, size = 20) {
  return el('span', {
    class: 'badge',
    'data-article': article,
    text: article,
    style: `font-size:${size}px;padding:${size * 0.35}px ${size * 0.65}px`,
  });
}

export function section(title, content) {
  return [title && el('div', { class: 'section-title', text: title }), content].filter(Boolean);
}

export function card(children) {
  return el('div', { class: 'card' }, children);
}

export function empty(title, description) {
  return el('div', { class: 'empty' }, [
    el('strong', { text: title }),
    el('span', { text: description }),
  ]);
}

/** Linha de substantivo: badge + palavra + tradução. */
export function nounRow(noun, onClick) {
  return el('button', { class: 'row', type: 'button', onClick: () => onClick(noun) }, [
    badge(noun.article, 14),
    el('span', { class: 'row-text' }, [
      el('div', { class: 'row-word', text: noun.word }),
      el('div', {
        class: 'row-sub',
        text: noun.translation || 'Sem tradução em português',
      }),
    ]),
  ]);
}

export function clear(node) {
  node.replaceChildren();
  return node;
}

export const CONTACT_EMAIL = 'contato@derdiedas.app.br';

/**
 * Link de reporte. Sem backend, a via mais simples é um e-mail com os dados da
 * palavra já preenchidos — nada é enviado sem o usuário revisar e confirmar.
 */
export function reportLink(noun, origin = 'web') {
  const subject = `DerDieDas — correção: ${noun.article} ${noun.word}`;
  const body = [
    'Encontrei algo errado nesta palavra:',
    '',
    `Palavra:  ${noun.word}`,
    `Artigo:   ${noun.article}`,
    `Tradução: ${noun.translation || '(sem tradução)'}`,
    `Plural:   ${noun.plural || '(sem plural)'}`,
    '',
    'O que está errado?',
    '',
    '',
    `— enviado pelo DerDieDas (${origin})`,
  ].join('\n');

  return el('a', {
    class: 'report-link',
    href: `mailto:${CONTACT_EMAIL}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`,
    text: 'Reportar erro nesta palavra',
  });
}
