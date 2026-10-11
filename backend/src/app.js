import express from 'express';
import compression from 'compression';
import { api } from './routes/index.js';
import { notFound, errorHandler } from './middleware/errors.js';
import { anon, must } from './db.js';

export const app = express();
app.disable('x-powered-by');
// One JSON line per request; Railway parses these into filterable fields (@level:error, @path:…, @user:…).
// Never headers or bodies: they carry the bearer token and people's financial data.
app.use((req, res, next) => {
  if (req.path.startsWith('/health')) return next(); // uptime pings would drown everything else
  const start = performance.now();
  const path = req.originalUrl.split('?')[0].replace(/\/\d+(?=\/|$)/g, '/:id');
  res.on('finish', () => {
    const status = res.statusCode;
    console.info(JSON.stringify({
      level: status >= 500 ? 'error' : status >= 400 ? 'warn' : 'info',
      message: `${req.method} ${path} ${status}`,
      method: req.method,
      path,
      status,
      ms: Math.round(performance.now() - start),
      user: req.userId,
    }));
  });
  next();
});
// JSON-only API: nothing here should ever be sniffed, framed, or run as a page.
app.use((req, res, next) => {
  res.set({
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'X-Content-Type-Options': 'nosniff',
    'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
  });
  next();
});
// Dart's HttpClient asks for gzip by default; full-list JSON shrinks ~90%.
app.use(compression());
app.use(express.json({ limit: '1mb' }));
app.get('/health', (req, res) => res.send('ok'));
// For an external uptime monitor: Node is up *and* Supabase answers (an outage or hibernated DB 500s here).
// No retries: user GETs retry 3x with backoff, but a health check should report the first failure.
app.get('/health/db', (req, res) =>
  must(anon.from('user_settings').select('user_id').limit(1).retry(false)).then(() => res.send('ok')));
app.use('/v1', api);
app.use(notFound);
app.use(errorHandler);
