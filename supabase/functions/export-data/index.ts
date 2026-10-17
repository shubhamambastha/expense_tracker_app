// "Export Data": emails the caller's transactions, accounts and budgets as CSV attachments
// to the email on their own login. Called by the Node API (POST /v1/data/export), which
// forwards the user's bearer token. Reads go through RLS as that user, and the recipient
// is always the token's own email, so calling this directly can only ever mail yourself.
// Deploy with --no-verify-jwt: the token is verified below by getUser (works with asymmetric keys).
import { Buffer } from 'node:buffer';
import { createClient } from 'npm:@supabase/supabase-js@2';
import { EXPORTS, toCsv } from './csv.ts';

const json = (body: unknown, status: number) => Response.json(body, { status });

// Supabase caps a response at max_rows (default 1000), so page until a short page.
const PAGE = 1000;

Deno.serve(async (req) => {
  const { RESEND_API_KEY, EXPORT_FROM_EMAIL } = Deno.env.toObject();
  if (!RESEND_API_KEY || !EXPORT_FROM_EMAIL) {
    console.error('export-data: RESEND_API_KEY / EXPORT_FROM_EMAIL not set');
    return json({ error: 'Export by email is not configured.' }, 503);
  }
  const token = req.headers.get('Authorization')?.match(/^Bearer (.+)$/)?.[1];
  if (!token) return json({ error: 'Missing bearer token' }, 401);
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: { user } } = await db.auth.getUser(token);
  if (!user) return json({ error: 'Invalid or expired token' }, 401);
  if (!user.email) return json({ error: 'Your account has no email address.' }, 400);

  const attachments = [];
  for (const [filename, table, cols] of EXPORTS) {
    const rows: Record<string, unknown>[] = [];
    for (;;) {
      const { data, error } = await db.from(table).select().eq('user_id', user.id)
        .order('id').range(rows.length, rows.length + PAGE - 1);
      if (error) {
        console.error(`export-data: read ${table} failed: ${error.code}`);
        return json({ error: 'Could not read your data.' }, 500);
      }
      rows.push(...data);
      if (data.length < PAGE) break;
    }
    attachments.push({ filename, content: Buffer.from(toCsv(rows, cols)).toString('base64') });
  }

  const sent = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from: EXPORT_FROM_EMAIL,
      to: [user.email],
      subject: 'Your expense data export',
      text: 'Attached: your transactions, accounts and budgets as CSV files. They open in Excel, Numbers or Google Sheets.',
      attachments,
    }),
    signal: AbortSignal.timeout(15_000),
  });
  if (!sent.ok) {
    console.error(`export-data: resend rejected the email: ${sent.status}`);
    return json({ error: 'Could not send the email.' }, 502);
  }
  return json({ email: user.email }, 202);
});
