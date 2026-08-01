// Aba Sobre — porte de Artikel/Views/CreditsView.swift.

import { allNouns } from '../data.js';
import { exportData, importData } from '../store.js';
import { el, card, section, CONTACT_EMAIL } from '../ui.js';

const VERSION = '1.0 (web)';

function paragraphs(...texts) {
  return card(texts.map((text) => el('p', { text })));
}

function linkRow(href, label) {
  return el('a', { class: 'link-row', href, rel: 'noopener', target: '_blank', text: label });
}

function creditRow(title, detail) {
  return el('div', { class: 'stat-row' }, [
    el('span', { text: title }),
    el('span', { class: 'value', text: detail }),
  ]);
}

function backupCard() {
  const fileInput = el('input', {
    type: 'file',
    accept: 'application/json',
    style: 'display:none',
  });

  fileInput.addEventListener('change', async () => {
    const file = fileInput.files?.[0];
    if (!file) return;
    try {
      importData(await file.text());
      alert('Dados restaurados. O app será recarregado.');
      location.reload();
    } catch {
      alert('Não foi possível ler esse arquivo de backup.');
    }
  });

  const exportRow = el('button', {
    class: 'row',
    type: 'button',
    text: 'Exportar meus dados',
    onClick: () => {
      const blob = new Blob([exportData()], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = el('a', { href: url, download: 'derdiedas-backup.json' });
      link.click();
      URL.revokeObjectURL(url);
    },
  });

  const importRow = el('button', {
    class: 'row',
    type: 'button',
    text: 'Importar backup',
    onClick: () => fileInput.click(),
  });

  return card([exportRow, importRow, fileInput]);
}

const element = el('section', { class: 'view about', id: 'view-about', hidden: true });

export function onShow() {
  const total = allNouns().length.toLocaleString('pt-BR');

  element.replaceChildren(
    el('div', { class: 'about-header' }, [
      el('img', { src: './icons/icon-192.png', alt: '' }),
      el('div', { class: 'name', text: 'DerDieDas' }),
      el('div', { class: 'version', text: `Versão ${VERSION}` }),
    ]),

    ...section(
      'Sobre',
      paragraphs(
        'Aprender alemão tem um obstáculo que quase todo brasileiro conhece: decorar se cada substantivo é der, die ou das. Não existe atalho fácil — e foi para atacar exatamente essa dificuldade que o DerDieDas nasceu.',
        'Em vez de jogar você contra um dicionário gigante cheio de termos técnicos e palavras raras, o app oferece uma seleção curada de substantivos realmente úteis do cotidiano (níveis A1 a B1), cada um com artigo, tradução em português e plural. Treinando o vocabulário certo, você também começa a enxergar os padrões escondidos da língua: palavras terminadas em -ung são sempre die, as em -chen são das, infinitivos substantivados são das, e por aí vai.',
        'Com busca instantânea, dois modos de treino, histórico e estatísticas dos seus erros, o DerDieDas foi feito para caber na sua rotina e transformar a parte mais espinhosa do alemão em prática rápida — e sem frustração.'
      )
    ),

    ...section(
      'Como foi feito',
      paragraphs(
        'O ponto de partida foi a lista aberta german-nouns, compilada do Wikcionário alemão (WiktionaryDE): mais de 90 mil substantivos com artigo e plural — a maioria composta por termos químicos, moedas antigas e palavras raríssimas que ninguém usa no dia a dia.',
        'Num script em Python (Google Colab), essa lista passou por um filtro de frequência de uso com a biblioteca wordfreq: só permaneceram as palavras que aparecem pelo menos cerca de 1 vez por milhão no alemão real — o corte de 1e-6 (0,0001%). Isso derruba automaticamente a cauda longa de termos raros. Uma segunda passada ainda removeu duplicatas, abreviações e verbos infiltrados.',
        `O resultado são os ${total} substantivos do app, cada um traduzido para o português com o Google Tradutor. Os scripts foram escritos com apoio do Google Gemini.`
      )
    ),

    ...section(
      'Ferramentas',
      card([
        creditRow('Base de dados', 'german-nouns · WiktionaryDE'),
        creditRow('Filtro de frequência', 'wordfreq · corte 1e-6'),
        creditRow('Traduções', 'Google Tradutor'),
        creditRow('Scripts', 'Google Gemini · Colab'),
        creditRow('Versão nativa', 'SwiftUI · iOS e watchOS'),
      ])
    ),

    ...section(
      'Créditos & Licenças',
      card([
        el('p', {
          text: 'A base de artigos e plurais vem do projeto aberto german-nouns, compilado do WiktionaryDE e publicado sob a licença Creative Commons Atribuição-CompartilhaIgual 4.0 (CC BY-SA 4.0). As traduções para o português foram geradas com o Google Tradutor.',
          style: 'font-size:13px;color:var(--secondary)',
        }),
        linkRow('https://github.com/gambolputty/german-nouns', 'Projeto german-nouns'),
        linkRow('https://de.wiktionary.org', 'WiktionaryDE'),
        linkRow('https://creativecommons.org/licenses/by-sa/4.0/deed.pt_BR', 'Licença CC BY-SA 4.0'),
      ])
    ),

    ...section(
      'Contato',
      card([
        el('a', {
          class: 'link-row',
          href: `mailto:${CONTACT_EMAIL}?subject=${encodeURIComponent('DerDieDas — contato')}`,
          text: 'Reportar erro ou sugerir melhoria',
        }),
      ])
    ),

    ...section(
      'Privacidade',
      card([linkRow('./privacidade.html', 'Política de Privacidade')])
    ),

    ...section('Backup', backupCard()),

    el('p', {
      style: 'margin:18px 4px 0;font-size:12px;color:var(--secondary);text-align:center',
      text: 'Seus dados ficam apenas neste dispositivo. Adicione o app à tela de início para não perdê-los.',
    })
  );
}

export { element };
