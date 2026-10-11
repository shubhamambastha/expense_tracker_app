export const notFound = (req, res) => res.status(404).json({ error: 'Not found' });

// Fixed client-facing text: raw Postgres messages name constraints and indexes. Those go to the log instead.
const MESSAGES = {
  400: 'Invalid request.', 401: 'Invalid or expired token', 403: 'Not allowed.',
  404: 'Not found', 409: 'That already exists or is still in use.', 413: 'Request too large.',
};

// Express spots error handlers by their 4 arguments, so `next` must stay.
export function errorHandler(err, req, res, next) {
  const status = err.status ?? 500;
  // JSON for Railway. Never PostgREST's `details`/`hint`: they can echo a whole row of someone's finances.
  if (status >= 500) console.error(JSON.stringify({ level: 'error', message: err.message, status, code: err.code, stack: err.stack }));
  else if (err.code) console.warn(JSON.stringify({ level: 'warn', message: err.message, status, code: err.code }));
  const error = MESSAGES[status] ?? (status >= 500 ? 'Internal server error' : 'Request failed.');
  res.status(status).json({ error, code: err.code });
}
