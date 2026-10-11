import { list, row, send, sendAll, deleteOwn } from '../db.js';
import { resourceRouter } from './resource-router.js';

const COLUMNS = ['category_name', 'monthly_limit', 'currency_code'];

const router = resourceRouter();
export default router;

router.get('/', (req, res) => sendAll(res, () => list(req, 'category_budgets').order('category_name')));
// Upserts on (user_id, category_name).
router.post('/', (req, res) =>
  send(res, req.db.from('category_budgets')
    .upsert(row(req, COLUMNS), { onConflict: 'user_id,category_name' })
    .select().single()));
router.delete('/:id', (req, res) => send(res, deleteOwn(req, 'category_budgets'), 204));
