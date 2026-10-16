import { Router } from 'express';
import { must } from '../db.js';

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
