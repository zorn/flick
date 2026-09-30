# Ecto migration-safety guardrails

Researched 2026-09-29 for [issue #226](https://github.com/zorn/flick/issues/226) against excellent_migrations 0.1.10, jump_credo_checks 0.5.0, squawk 2.66.0, ecto_sql 3.14.0 (the version in `mix.lock`), credo 1.7.19, and PostgreSQL 18 docs. All three tools were run against Flick's five migrations; see "Verification" below.

## Answer

1. **Tool: adopt `excellent_migrations` through its Credo check.** It runs inside the `mix credo --strict` that CI and `mix precommit` already run, needs no database, and covers the Safe Ecto Migrations recipes that an AI-written migration is most likely to break. Squawk sees the real SQL but needs a migrated database, log scraping, and rule tuning to stop fighting Ecto's defaults.
2. **Legacy migrations: baseline with a cutoff.** Set `config :excellent_migrations, start_after: "20260927221423"` in `config/config.exs`, and pass the same `start_after` to the Jump checks. Do not edit or annotate the five applied migrations; editing them cannot change the production schema.
3. **Round-trip: yes.** Add `mix ecto.rollback --all && mix ecto.migrate` after the existing migrate step in `build-and-test.yaml`. All five migrations round-trip cleanly today, including the backfill.
4. **`PreferTextColumns`: adopt with the same cutoff, and skip the rewrite.** Postgres gains nothing from `varchar(255)`, so new migrations should use `:text`. The two 2024 `:string` columns can stay; converting them buys little and would remove the only length guard on `votes.full_name`.
5. **`PreferChangeOverUpDownMigrations`: adopt with the same cutoff.** It is cheap, and it correctly leaves the backfill migration alone.

## Options compared

| | excellent_migrations | Squawk on generated SQL | Jump migration checks |
|---|---|---|---|
| Input | Migration AST | SQL captured from a real migrate run | Migration AST |
| Runs in | `mix credo` | Separate binary (npm, pip, Docker) | `mix credo` |
| Needs a database | No | Yes | No |
| Legacy handling | `start_after` timestamp, per-line and per-file comments | `--exclude-path`, `squawk-ignore` comments in SQL | `start_after`, `excluded` (up/down check only) |
| Latest release | 0.1.10, 2026-03-06 | 2.66.0, 2026-09-23 | 0.5.0, 2026-08-21 |

### excellent_migrations

**What it catches.** It flags 19 danger types from the migration AST: non-concurrent indexes, foreign keys without `validate: false`, removed or renamed columns and tables, `modify`, `NOT NULL` via `modify`, check constraints, defaults on `alter`, `:json` columns, raw `execute`, and `Repo` writes ([README](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/README.md#checks)). The recipes credit fly.io's Safe Ecto Migrations guide ([README](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/README.md#similar-tools--resources)), which now ships as an ecto_sql guide ([safe_migrations.md](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/guides/safe_migrations.md)).

**How to configure.** Add `{ExcellentMigrations.CredoCheck.MigrationsSafety, []}` to the enabled checks and `"priv/repo/migrations/"` to `files.included` in `.credo.exs` ([README](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/README.md#credo-check)). Flick's `.credo.exs` does not include `priv/` today, so both lines are needed. A Credo warning fails the run with a non-zero exit ([Credo exit statuses](https://github.com/rrrene/credo/blob/v1.7.19/guides/introduction/exit_statuses.md)).

**Legacy migrations.** `start_after` skips every file whose timestamp is not strictly greater than the value ([files_finder.ex](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/lib/files_finder.ex#L12-L17)), and the Credo check reads it from application config ([migrations_safety.ex](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/lib/credo_check/migrations_safety.ex#L23-L30)). A single danger can be accepted with `# excellent_migrations:safety-assured-for-next-line <type>` or `...-for-this-file <type>` ([README](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/README.md#assuring-safety)).

**Blind spots.**

- It flags every `create index` without `concurrently: true`, even on a table created in the same migration ([ast_parser.ex](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/lib/ast_parser.ex#L47-L60)). A `references` column inside `create table` is flagged too ([ast_parser.ex](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/lib/ast_parser.ex#L163-L173)). New tables will need a `safety-assured` comment, which also serves as a visible "I thought about this" marker.
- It detects writes only as calls on a module alias containing `Repo`, such as `Repo.update_all` ([ast_parser.ex](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/lib/ast_parser.ex#L202-L211)). `repo().query!("UPDATE ...")` is invisible to it.
- It reports `execute` as `raw_sql_executed` without reading the SQL ([ast_parser.ex](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/lib/ast_parser.ex#L101-L105)).

**Maintenance.** One maintainer, releases in 2024-02, 2025-09, and 2026-03, 12 open pull requests, not archived ([changelog](https://github.com/artur-sulej/excellent_migrations/blob/v0.1.10/CHANGELOG.md); [Hex](https://hex.pm/packages/excellent_migrations)). It is slow-moving but alive, and it is widely used (about 31,000 downloads per week on Hex).

### Squawk on generated SQL

**What it catches.** Squawk lints Postgres SQL for statements that block reads or writes or break existing clients ([rules overview](https://github.com/sbdchd/squawk/blob/v2.66.0/docs/docs/rules-overview.md)). Because it reads real SQL, it knows an index on a table created in the same file is safe, and it checks the SQL inside `execute`.

**How it fits Ecto.** Squawk has no special support for any ORM ([web frameworks](https://github.com/sbdchd/squawk/blob/v2.66.0/docs/docs/web-frameworks.md)). The SQL has to come from `mix ecto.migrate --log-migrations-sql` ([ecto.migrate.ex](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/lib/mix/tasks/ecto.migrate.ex#L76)), which needs a live database and a script to split the log into one file per migration. Data-dependent statements appear only when rows exist, so an empty CI database hides the backfill's `UPDATE`s.

**Noise.** Two rule groups fight Ecto's defaults. `prefer-timestamp-tz` fires on every Ecto timestamp, because Ecto maps `:utc_datetime_usec` to `timestamp` ([connection.ex](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/lib/ecto/adapters/postgres/connection.ex#L2070-L2071)). `require-lock-timeout` and `require-statement-timeout` fire on every file. All three would need `excluded_rules` in `.squawk.toml` ([CLI docs](https://github.com/sbdchd/squawk/blob/v2.66.0/docs/docs/cli.md#squawktoml-configuration-file)).

**Legacy migrations.** `--exclude-path` or `excluded_paths` skips files by glob, and `-- squawk-ignore` comments work per statement ([CLI docs](https://github.com/sbdchd/squawk/blob/v2.66.0/docs/docs/cli.md#files)). Neither maps cleanly onto generated SQL, so a cutoff would live in the glue script.

**Maintenance.** Very active; 2.66.0 shipped 2026-09-23 ([release](https://github.com/sbdchd/squawk/releases/tag/v2.66.0)). Installs through npm, pip, or Docker ([quick start](https://github.com/sbdchd/squawk/blob/v2.66.0/docs/docs/quick_start.md)), which adds a toolchain Flick does not otherwise need.

**Verdict.** Squawk is the stronger linter in isolation, but the glue script, the database dependency, and the rule tuning cost more than Flick's scale justifies. Revisit it if excellent_migrations' false positives or blind spots start to bite.

### Jump migration checks

`Jump.CredoChecks.PreferTextColumns` flags any `add` or `modify` with `:string` ([prefer_text_columns.ex](https://github.com/Jump-App/credo_checks/blob/v0.5.0/lib/jump/credo_checks/prefer_text_columns.ex#L53-L62)). `PreferChangeOverUpDownMigrations` flags an `up`/`down` pair whose `up` holds only operations Ecto can reverse by itself ([prefer_change_over_up_down_migrations.ex](https://github.com/Jump-App/credo_checks/blob/v0.5.0/lib/jump/credo_checks/prefer_change_over_up_down_migrations.ex)). Both take a `start_after` parameter in `.credo.exs` ([README](https://github.com/Jump-App/credo_checks/blob/v0.5.0/README.md#installation-and-configuration)). Neither is a lock-safety check; they are style guardrails that complement excellent_migrations. The package is young (0.1.0 in 2026-04) but ships monthly ([Hex](https://hex.pm/packages/jump_credo_checks)).

**The case for `:text`.** Postgres documents no performance difference between `text` and `varchar(n)` beyond a length check on write ([character types](https://www.postgresql.org/docs/18/datatype-character.html)). Ecto's `:string` becomes `varchar(255)` ([connection.ex](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/lib/ecto/adapters/postgres/connection.ex#L1857)), and widening it later means an `ALTER COLUMN TYPE` under an `ACCESS EXCLUSIVE` lock. Changing `varchar` to `text` is binary coercible, so it needs no table rewrite ([ALTER TABLE notes](https://www.postgresql.org/docs/18/sql-altertable.html#SQL-ALTERTABLE-NOTES)).

**Why not convert the two 2024 columns.** `ballots.url_slug` already has `validate_length(max: 255)` in `Ballot.changeset/2`, so the database limit adds nothing there. `votes.full_name` has no length validation in `Vote`, so `varchar(255)` is its only guard today. Converting it to `text` would need a `validate_length` first. Neither change is worth a migration on its own.

## How each tool treats the backfill migration

`20260927221423_convert_possible_answers_to_embeds.exs` adds a `jsonb` column, backfills it row by row with `repo().query!`, drops the old column, renames the new one, and sets `NOT NULL` through `execute`.

- **excellent_migrations** flags `column_removed`, `column_renamed`, and `raw_sql_executed` in both `up` and `down`. It misses the backfill and the `NOT NULL`, because both hide behind `repo().query!` and `execute`.
- **Squawk** flags `ban-drop-column`, `renaming-column`, and `adding-not-nullable-field`. It never sees the backfill on an empty database, and no Squawk rule targets `UPDATE`.
- **Jump checks** raise nothing. The `up` holds `flush()` and queries, so `PreferChangeOverUpDownMigrations` rightly keeps `up`/`down`.

The Safe Ecto Migrations guide would split this into a schema migration plus a separate, batched data migration outside the transaction ([backfilling_data.md](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/guides/backfilling_data.md)). The guide also says scale is the biggest factor ([safe_migrations.md](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/guides/safe_migrations.md#all-scenarios)). With hundreds of ballots, one transaction is the better trade: it is atomic, and a failure leaves nothing half-migrated. The migration already follows the guide's main rule by using raw SQL instead of application schemas. The real risk is deploy ordering. Render keeps the old instance serving while the new one starts ([Render deploys](https://render.com/docs/deploys)), and Flick migrates in the new instance's start command (`render.yaml`), so a dropped or renamed column can break the old instance for a few seconds. That is exactly what `column_removed` and `column_renamed` exist to make someone acknowledge.

## Round-trip check

**What to run.** In `build-and-test.yaml`, after `mix ecto.migrate`, add a step that runs `mix ecto.rollback --all && mix ecto.migrate` (`MIX_ENV=test` is already set). `--all` reverts every applied migration ([ecto.rollback.ex](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/lib/mix/tasks/ecto.rollback.ex#L49)).

**What it catches.** A `change` that uses a command Ecto cannot reverse, such as `modify` without `:from` or `remove` without a type ([migration.ex](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/lib/ecto/migration.ex#L1381), [L1444](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/lib/ecto/migration.ex#L1444)), raises "cannot reverse migration command" on rollback ([runner.ex](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/lib/ecto/migration/runner.ex#L223)). It also catches a hand-written `down` that crashes, and an `up` that cannot run twice.

**What it misses.** CI rolls back an empty database, so data paths such as the backfill loop run zero times. It also does not compare the schema before and after. A `pg_dump -s` diff would, but the runner's `pg_dump` would have to match the Postgres 18 service, which is not worth the setup.

## Verification

All probes ran locally against Postgres on an isolated database (`MIX_TEST_PARTITION=_migprobe`), which was dropped afterward. `mix.exs` and `mix.lock` were restored byte for byte (checked with `shasum`).

- **Round-trip, empty database:** `mix ecto.rollback --all` then `mix ecto.migrate` succeeded for all five migrations. `pg_dump -s` output was identical before and after.
- **Round-trip, with data:** two ballots inserted in the pre-embeds format (`"Pizza,Tacos , Sushi"` and `"A, A, B"`) went up to embeds, down to text (`"Pizza, Tacos, Sushi"`, `"A, A, B"`), and up again. The down path normalizes spacing, and the up path generates fresh embed ids, which is fine because votes reference answers by text. An answer containing a comma made `down` raise as designed, and the transaction left the migration applied and untouched.
- **excellent_migrations** (`mix excellent_migrations.check_safety`, exit 1) reported 9 dangers: 2 `index_not_concurrently` in the ballots migration, 1 `column_reference_added` in the votes migration, and 6 in the backfill migration. With `start_after: "20260927221423"` in `config/config.exs`, both the mix task and the Credo check reported none.
- **Jump checks** through a scratch `.credo.exs`: `PreferTextColumns` flagged `url_slug` and `full_name`. `PreferChangeOverUpDownMigrations` flagged nothing.
- **Squawk 2.66.0** on SQL from `--log-migrations-sql` (`--pg-version=18.0 --assume-in-transaction`): 21 warnings. 16 were `prefer-timestamp-tz` and the two timeout rules. The rest were `prefer-text-field` on the two `varchar(255)` columns, plus `ban-drop-column`, `renaming-column`, and `adding-not-nullable-field` in the backfill migration. It did not flag the unique indexes on the new `ballots` table.
