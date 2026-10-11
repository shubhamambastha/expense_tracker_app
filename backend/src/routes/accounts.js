import { list, pick, row, send, sendAll, updateOwn, deleteOwn } from '../db.js';
import { resourceRouter } from './resource-router.js';

const COLUMNS = [
  'name', 'type', 'opening_balance', 'credit_limit', 'statement_day', 'due_day',
  'nickname', 'provider_name', 'notes', 'is_archived', 'linked_account_id',
  'wallet_provider',
];

const router = resourceRouter();
export default router;

router.get('/', (req, res) => sendAll(res, () => {
  const query = list(req, 'accounts');
  return (req.query.includeArchived === 'true' ? query : query.eq('is_archived', false)).order('name');
}));
router.post('/', (req, res) =>
  send(res, req.db.from('accounts').insert(row(req, COLUMNS)).select().single(), 201));
router.patch('/:id', (req, res) => send(res, updateOwn(req, 'accounts', pick(req.body, COLUMNS))));
router.delete('/:id', (req, res) => send(res, deleteOwn(req, 'accounts'), 204));
