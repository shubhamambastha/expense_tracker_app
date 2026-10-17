// Pure, so it runs under both Deno (the function) and Node (csv.test.ts).

// Quote only when needed (RFC 4180).
const cell = (v: unknown) => {
  const text = v == null ? '' : String(v);
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
};

export const toCsv = (rows: Record<string, unknown>[], cols: string[]) =>
  [cols, ...rows.map((r) => cols.map((c) => r[c]))]
    .map((line) => line.map(cell).join(',')).join('\r\n') + '\r\n';

// Headers are the DB column names; ids and user_id are never exported.
export const EXPORTS: [filename: string, table: string, cols: string[]][] = [
  ['transactions.csv', 'transactions', ['date', 'kind', 'amount', 'currency_code', 'category',
    'counterparty_name', 'note', 'is_recurring', 'recurrence_frequency']],
  ['accounts.csv', 'accounts', ['name', 'type', 'opening_balance', 'credit_limit', 'nickname', 'provider_name', 'is_archived']],
  ['budgets.csv', 'category_budgets', ['category_name', 'monthly_limit', 'currency_code']],
];
