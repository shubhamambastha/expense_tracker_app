import express from 'express';
import { api } from './routes/index.js';
import { notFound, errorHandler } from './middleware/errors.js';

export const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '1mb' }));
app.get('/health', (req, res) => res.send('ok'));
app.use('/v1', api);
app.use(notFound);
app.use(errorHandler);
