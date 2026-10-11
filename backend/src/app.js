import express from 'express';
import { api } from './routes/index.js';
import { notFound, errorHandler } from './middleware/errors.js';

export const app = express();
app.disable('x-powered-by');
// JSON-only API: nothing here should ever be sniffed, framed, or run as a page.
app.use((req, res, next) => {
  res.set({
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'X-Content-Type-Options': 'nosniff',
    'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
  });
  next();
});
app.use(express.json({ limit: '1mb' }));
app.get('/health', (req, res) => res.send('ok'));
app.use('/v1', api);
app.use(notFound);
app.use(errorHandler);
