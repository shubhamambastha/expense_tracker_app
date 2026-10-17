// node --test supabase/functions/export-data/csv.test.ts  (Deno runs node:test too)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { toCsv } from './csv.ts';

test('toCsv quotes only fields that need it and leaves out unlisted columns', () => {
  const rows = [{ id: 9, user_id: 'u', date: '2026-10-01', amount: -4.5, note: 'tea, "chai"\nhot', paused: null }];
  assert.equal(
    toCsv(rows, ['date', 'amount', 'note', 'paused']),
    'date,amount,note,paused\r\n2026-10-01,-4.5,"tea, ""chai""\nhot",\r\n',
  );
  assert.equal(toCsv([], ['a', 'b']), 'a,b\r\n');
});
