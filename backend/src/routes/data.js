import { Router } from 'express';
import { fetchAll, list, must } from '../db.js';
import { RESEND_API_KEY, EXPORT_FROM_EMAIL } from '../config.js';

const router = Router();
export default router;

// Children before parents, so FKs never block a delete.
export const USER_TABLES = [
  'recurring_events', 'transactions', 'accounts',
  'category_budgets', 'expense_categories', 'income_categories',
];

export async function wipe(req, tables) {
  for (const table of tables) await must(req.db.from(table).delete().eq('user_id', req.userId));
}

// "Reset My Account": wipes everything except user_settings and counterparties (autofill history).
// ponytail: not atomic — a mid-way failure leaves a partial wipe; move to a Postgres function if that bites.
router.delete('/', async (req, res) => {
  await wipe(req, USER_TABLES);
  res.status(204).end();
});

// Quote only when needed (RFC 4180). Headers are the DB column names; ids and user_id are never exported.
const cell = (v) => (/[",\r\n]/.test(v ??= '') ? `"${String(v).replaceAll('"', '""')}"` : String(v));
export const toCsv = (rows, cols) => [cols, ...rows.map((r) => cols.map((c) => r[c]))]
  .map((line) => line.map(cell).join(',')).join('\r\n') + '\r\n';

const EXPORTS = [
  ['transactions.csv', 'transactions', ['date', 'kind', 'amount', 'currency_code', 'category',
    'counterparty_name', 'note', 'is_recurring', 'recurrence_frequency']],
  ['accounts.csv', 'accounts', ['name', 'type', 'opening_balance', 'credit_limit', 'nickname', 'provider_name', 'is_archived']],
  ['budgets.csv', 'category_budgets', ['category_name', 'monthly_limit', 'currency_code']],
];

// "Export Data": emails the caller's data as CSV attachments to the address on their login.
// ponytail: synchronous and unthrottled (a user can only mail themselves); queue it if exports outgrow a request.
router.post('/export', async (req, res) => {
  if (!RESEND_API_KEY || !EXPORT_FROM_EMAIL) {
    throw Object.assign(new Error('export email not configured (RESEND_API_KEY / EXPORT_FROM_EMAIL)'), { status: 503 });
  }
  if (!req.email) return res.status(400).json({ error: 'Your account has no email address.' });
  const attachments = await Promise.all(EXPORTS.map(async ([filename, table, cols]) => ({
    filename,
    content: Buffer.from(toCsv(await fetchAll(() => list(req, table)), cols)).toString('base64'),
  })));
  const sent = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from: EXPORT_FROM_EMAIL,
      to: [req.email],
      subject: 'Your expense data export',
      text: 'Attached: your transactions, accounts and budgets as CSV files. They open in Excel, Numbers or Google Sheets.',
      attachments,
    }),
    signal: AbortSignal.timeout(15_000),
  });
  if (!sent.ok) throw Object.assign(new Error(`resend rejected export email: ${sent.status}`), { status: 502 });
  res.status(202).json({ email: req.email });
});
