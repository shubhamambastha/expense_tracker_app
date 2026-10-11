export const notFound = (req, res) => res.status(404).json({ error: 'Not found' });

// Fixed client-facing text: raw Postgres messages name constraints and indexes. Details go to the log.
const MESSAGES = {
  400: 'Invalid request.', 401: 'Invalid or expired token', 403: 'Not allowed.',
  404: 'Not found', 409: 'That already exists or is still in use.', 413: 'Request too large.',
};

// Express spots error handlers by their 4 arguments, so `next` must stay.
export function errorHandler(err, req, res, next) {
  const status = err.status ?? 500;
  if (status >= 500) console.error(err);
  else if (err.code) console.warn(status, err.code, err.message);
  const error = MESSAGES[status] ?? (status >= 500 ? 'Internal server error' : 'Request failed.');
  res.status(status).json({ error, code: err.code });
}
