import { Router } from 'express';
import { auth } from '../middleware/auth.js';
import transactions from './transactions.js';
import recurringEvents from './recurring-events.js';
import accounts from './accounts.js';
import budgets from './budgets.js';
import categories from './categories.js';
import settings from './settings.js';
import data from './data.js';

// Everything under /v1 is authenticated and scoped to the caller.
export const api = Router();
api.use(auth);
api.use('/transactions', transactions);
api.use('/recurring-events', recurringEvents);
api.use('/accounts', accounts);
api.use('/budgets', budgets);
api.use('/categories/expense', categories('expense_categories'));
api.use('/categories/income', categories('income_categories'));
api.use('/settings', settings);
api.use('/data', data);
