import { Router } from 'express';
import { must } from '../db.js';

const router = Router();
export default router;

// "Reset My Account": wipes everything except user_settings. Order respects FKs.
// ponytail: not atomic — a mid-way failure leaves a partial wipe; move to a Postgres function if that bites.
router.delete('/', async (req, res) => {
  for (const table of [
    'recurring_events', 'transactions', 'accounts',
    'category_budgets', 'expense_categories', 'income_categories',
  ]) {
    await must(req.db.from(table).delete().eq('user_id', req.userId));
  }
  res.status(204).end();
});
