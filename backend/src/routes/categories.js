import { list, must, row, send, sendAll, deleteOwn } from '../db.js';
import { resourceRouter } from './resource-router.js';

const COLUMNS = ['name', 'icon', 'sort_order', 'is_default'];

// Expense and income categories share a shape; only the table differs.
export default function categories(table) {
  const router = resourceRouter();
  router.get('/', (req, res) => sendAll(res, () => list(req, table).order('sort_order').order('name')));
  // Takes one object or an array (default seeding).
  router.post('/', async (req, res) => {
    const rows = [].concat(req.body).map((body) => row(req, COLUMNS, body));
    const data = await must(req.db.from(table).insert(rows, { defaultToNull: false }).select());
    res.status(201).json(Array.isArray(req.body) ? data : data[0]);
  });
  // Seeded defaults are never deletable.
  router.delete('/:id', (req, res) => send(res, deleteOwn(req, table).eq('is_default', false), 204));
  return router;
}
