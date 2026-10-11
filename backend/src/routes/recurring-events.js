import { list, row, send, sendAll, deleteOwn } from '../db.js';
import { resourceRouter } from './resource-router.js';

const COLUMNS = ['transaction_id', 'occurrence_date', 'event_type', 'snooze_until'];

const router = resourceRouter();
export default router;

router.get('/', (req, res) =>
  sendAll(res, () => list(req, 'recurring_events').order('occurrence_date', { ascending: false })));
// Upserts per occurrence, so repeat taps don't duplicate.
router.post('/', (req, res) =>
  send(res, req.db.from('recurring_events')
    .upsert(row(req, COLUMNS), { onConflict: 'user_id,transaction_id,occurrence_date,event_type' })
    .select().single(), 201));
router.delete('/:id', (req, res) => send(res, deleteOwn(req, 'recurring_events'), 204));
