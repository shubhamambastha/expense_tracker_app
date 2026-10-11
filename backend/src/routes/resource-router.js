import { Router } from 'express';
import { notFound } from '../middleware/errors.js';

// A router whose `:id` must be a bigint. Anything else 404s before reaching a query.
// router.param doesn't reach mounted sub-routers, so each resource router registers its own.
export const resourceRouter = () =>
  Router().param('id', (req, res, next, id) => (/^\d{1,18}$/.test(id) ? next() : notFound(req, res)));
