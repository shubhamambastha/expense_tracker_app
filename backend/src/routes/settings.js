import { Router } from 'express';
import { row, send } from '../db.js';

const COLUMNS = ['default_currency_code', 'preferences', 'onboarding_completed_at', 'updated_at'];

const router = Router();
export default router;

router.get('/', (req, res) =>
  send(res, req.db.from('user_settings').select().eq('user_id', req.userId).maybeSingle()));
// Upserts only the columns sent, so omitted ones keep their value.
router.patch('/', (req, res) =>
  send(res, req.db.from('user_settings').upsert(row(req, COLUMNS)).select().single()));
