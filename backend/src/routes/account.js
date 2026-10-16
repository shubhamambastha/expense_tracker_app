import { Router } from 'express';
import { admin, must } from '../db.js';
import { USER_TABLES, wipe } from './data.js';

const router = Router();
export default router;

// "Delete my account": every row the user owns, then the Supabase auth user itself.
// The auth user goes last, so a failure part-way leaves a signed-in user who can just retry.
router.delete('/', async (req, res) => {
  // Prove the service key works before destroying anything: a bad or rotated key must not wipe
  // the data and then fail to remove the login. 404 = already gone (a retry), so carry on.
  const { error: preflight } = await admin.auth.admin.getUserById(req.userId);
  if (preflight && preflight.status !== 404) {
    throw Object.assign(new Error(`auth admin preflight failed: ${preflight.code ?? preflight.message}`), { status: 500 });
  }
  await wipe(req, [...USER_TABLES, 'counterparties', 'user_settings']);
  // RLS turns a delete without a DELETE policy into a silent 0-row no-op (user_settings had none
  // until 20261012_user_settings_delete_policy.sql). Never drop the login while its data survives.
  const left = await must(req.db.from('user_settings').select('user_id').eq('user_id', req.userId));
  if (left.length) throw Object.assign(new Error('user_settings survived account deletion'), { status: 500 });
  const { error } = await admin.auth.admin.deleteUser(req.userId);
  // 404: already deleted by an earlier attempt whose response never arrived. Same outcome.
  // Anything else is ours (service key, outage), never the caller's: a 500 that doesn't echo GoTrue's code.
  if (error && error.status !== 404) {
    throw Object.assign(new Error(`auth user delete failed: ${error.code ?? error.message}`), { status: 500 });
  }
  res.status(204).end();
});
