import { Router } from 'express';
import { must } from '../db.js';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from '../config.js';

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

// "Export Data": the export-data Supabase Edge Function (supabase/functions/export-data) reads the
// caller's data as them, builds the CSVs and emails them to the address on their login.
// We forward the caller's own token, so the function's RLS reads and recipient match the API's user.
router.post('/export', async (req, res) => {
  const fn = await fetch(`${SUPABASE_URL}/functions/v1/export-data`, {
    method: 'POST',
    headers: { Authorization: req.get('authorization'), apikey: SUPABASE_ANON_KEY },
    signal: AbortSignal.timeout(30_000),
  });
  const body = await fn.json().catch(() => ({}));
  if (fn.status === 400) return res.status(400).json({ error: body.error ?? 'Invalid request.' });
  if (!fn.ok) throw Object.assign(new Error(`export-data function failed: ${fn.status}`), { status: 502 });
  res.status(202).json({ email: body.email });
});
