for (const key of ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'AUTH0_DOMAIN', 'AUTH0_CLIENT_ID']) {
  if (!process.env[key]) throw new Error(`Missing env ${key}`);
}
export const { SUPABASE_URL, SUPABASE_ANON_KEY, AUTH0_DOMAIN, AUTH0_CLIENT_ID } = process.env;
