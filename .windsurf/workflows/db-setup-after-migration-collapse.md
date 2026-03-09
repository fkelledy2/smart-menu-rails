---
description: Set up the database after migration history was collapsed to a SQL structure baseline
---
Use this workflow whenever you need to set up a fresh database in this repository.

1. Confirm the repository now uses `db/structure.sql` as the schema source of truth.
2. Do not rely on replaying the archived migration history in `db/migrate_archive/`.
3. Create the database with `bin/rails db:create` if it does not already exist.
4. Load the current schema baseline with `bin/rails db:schema:load`.
   - Because `config.active_record.schema_format = :sql`, Rails will load `db/structure.sql`.
5. Seed the database if needed with `bin/rails db:seed`.
6. For a full reset in local development, prefer `bin/rails db:reset`.
   - This will rebuild from the SQL structure baseline rather than replay old migrations.
7. When making future schema changes, add new forward migrations in `db/migrate/` as normal.
8. After future schema changes, regenerate the SQL baseline with `bin/rails db:schema:dump`.
9. Expect `bin/rails db:migrate:status` on existing databases to show many historical `NO FILE` entries.
   - This is expected because the legacy migration files were archived out of the active migration path.
10. If you need to inspect or recover old migration code, look in `db/migrate_archive/` rather than `db/migrate/`.
