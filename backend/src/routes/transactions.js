import { list, pick, row, send, sendAll, updateOwn, deleteOwn } from '../db.js';
import { resourceRouter } from './resource-router.js';

// Columns the client may write. `id` and `user_id` always come from the server.
const COLUMNS = [
  'kind', 'amount', 'currency_code', 'category', 'counterparty_name', 'note',
  'account_id', 'transfer_to_account_id', 'date', 'is_recurring', 'is_paused',
  'closed_at', 'recurrence_frequency', 'recurrence_start_date',
  'recurrence_end_date', 'reminder_timing',
];

const router = resourceRouter();
export default router;

router.get('/', (req, res) =>
  sendAll(res, () => list(req, 'transactions').order('date', { ascending: false })));
router.post('/', (req, res) =>
  send(res, req.db.from('transactions').insert(row(req, COLUMNS)).select().single(), 201));
router.patch('/:id', (req, res) => send(res, updateOwn(req, 'transactions', pick(req.body, COLUMNS))));
router.delete('/:id', (req, res) => send(res, deleteOwn(req, 'transactions'), 204));
