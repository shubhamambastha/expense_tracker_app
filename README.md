# expense_tracker_app

Flutter expense tracker with Auth0 login and Supabase persistence.

## Documentation

| Doc | Description |
| --- | --- |
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | App structure, services, navigation, state |
| [docs/DESIGN.md](./docs/DESIGN.md) | Design tokens, shared UI primitives, motion |
| [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md) | Postgres schema mind map, ER diagram, migrations |
| [docs/auth0_setup.md](./docs/auth0_setup.md) | Auth0 tenant & callback setup |
| [docs/supabase_setup.md](./docs/supabase_setup.md) | Supabase project, RLS, CI secrets |

## Getting started

1. Copy `config.dev.json.example` to `config.dev.json` and fill in keys.
2. Follow [docs/auth0_setup.md](./docs/auth0_setup.md) and [docs/supabase_setup.md](./docs/supabase_setup.md).
3. Run the app:

```bash
python3 scripts/define_from_json.py config.dev.json run
```
