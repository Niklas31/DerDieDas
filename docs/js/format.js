// Formatação espelhando o app iOS.

const relative = new Intl.RelativeTimeFormat('pt-BR', { numeric: 'auto' });
const percent = new Intl.NumberFormat('pt-BR', { style: 'percent', maximumFractionDigits: 0 });

const DAY_MS = 86400000;

function startOfDay(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

/**
 * Tempo relativo com granularidade de DIAS — igual ao Date+Extensions.swift,
 * que normaliza para o início do dia antes de comparar. Nunca mostra horas.
 * → "hoje", "ontem", "há 3 dias"
 */
export function formattedRelative(timestamp) {
  const days = Math.round((startOfDay(Date.now()) - startOfDay(timestamp)) / DAY_MS);
  return relative.format(-days, 'day');
}

/** Percentual sem casas decimais, como .percent.precision(.fractionLength(0)). */
export function formatPercent(value) {
  return percent.format(value);
}
