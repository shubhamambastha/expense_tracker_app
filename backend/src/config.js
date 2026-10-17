for (const key of ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY']) {
  if (!process.env[key]) throw new Error(`Missing env ${key}`);
}
export const { SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY } = process.env;
// A trailing slash would break the token issuer check (`${SUPABASE_URL}/auth/v1`) and 401 everyone.
export const SUPABASE_URL = process.env.SUPABASE_URL.replace(/\/+$/, '');
// Optional: without these, POST /v1/data/export answers 503 instead of the API refusing to boot.
export const { RESEND_API_KEY, EXPORT_FROM_EMAIL } = process.env;
