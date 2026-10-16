# expense_tracker_app

Flutter expense tracker with Supabase Auth login — email + password, Google, Apple (or an on-device guest mode) and a Node REST API (`backend/`) over Supabase Postgres.

## Documentation

| Doc | Description |
| --- | --- |
| [CLAUDE.md](./CLAUDE.md) | Project instructions for AI coding agents — conventions, commands, doc index |
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | App structure, services, navigation, state |
| [docs/DESIGN.md](./docs/DESIGN.md) | Design tokens, shared UI primitives, motion |
| [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md) | Postgres schema mind map, ER diagram, migrations |
| [docs/FEATURES.md](./docs/FEATURES.md) | Feature catalog with business/validation rules |
| [docs/BACKLOG.md](./docs/BACKLOG.md) | Known gaps, flagged-off features, structural debt |
| [docs/BACKEND.md](./docs/BACKEND.md) | Node API: endpoints, run locally, deploy |
| [docs/supabase_setup.md](./docs/supabase_setup.md) | Supabase project, auth providers (email + password, Google, Apple), RLS, CI secrets |
| [docs/RUNBOOK.md](./docs/RUNBOOK.md) | Incidents: where the logs are, symptom → cause → fix, rollback |
| [docs/DEPLOY_CHECKLIST.md](./docs/DEPLOY_CHECKLIST.md) | Production-readiness checklist, incl. the Supabase Auth cutover order (B4) |
| [TODOS.md](./TODOS.md) | Review follow-ups with priority/effort |
| [docs/designs/](./docs/designs/) | Point-in-time design docs (guest mode, onboarding, insight digest) |

## Getting started

1. Copy `config.dev.json.example` to `config.dev.json` and fill in keys.
2. Follow [docs/supabase_setup.md](./docs/supabase_setup.md) (database, auth providers, CI).
3. Start the API the app talks to (`backend/`), see [docs/BACKEND.md](./docs/BACKEND.md#run-locally).
4. Run the app:

```bash
python3 scripts/define_from_json.py config.dev.json run
```
