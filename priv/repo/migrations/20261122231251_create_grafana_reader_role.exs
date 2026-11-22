defmodule Flick.Repo.Migrations.CreateGrafanaReaderRole do
  @moduledoc """
  Creates `flick_grafana_reader`, the login role Grafana's Postgres data source
  uses. It may read every table, now and later, and write none.

  The role has no password here, because this repo is public. In production,
  set it once with psql's `\\password`. See issue #293.
  """

  use Ecto.Migration

  # Roles and grants have no Ecto functions. These statements touch no rows and
  # take no table locks.
  # excellent_migrations:safety-assured-for-this-file raw_sql_executed

  def up do
    # Roles belong to the whole server, not one database, and flick_dev and
    # flick_test share a server. Create the role only once.
    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'flick_grafana_reader') THEN
        CREATE ROLE flick_grafana_reader LOGIN CONNECTION LIMIT 3;
      END IF;
    END
    $$
    """

    # Guards against mistakes. The role can lift both itself, so the grants
    # below are the real boundary.
    execute "ALTER ROLE flick_grafana_reader SET default_transaction_read_only = on"
    execute "ALTER ROLE flick_grafana_reader SET statement_timeout = '5s'"

    execute "GRANT USAGE ON SCHEMA public TO flick_grafana_reader"
    execute "GRANT SELECT ON ALL TABLES IN SCHEMA public TO flick_grafana_reader"

    # A ballot's secret grants admin access to it in the app, so a reader who
    # could see it could also publish, close, or reweight that ballot. A
    # table-level grant covers every column, so swap it for column grants that
    # leave out secret. A column added to ballots later stays unreadable until
    # a migration grants it.
    execute "REVOKE SELECT ON ballots FROM flick_grafana_reader"

    execute """
    GRANT SELECT (id, question_title, url_slug, published_at, inserted_at,
      updated_at, description, closed_at, possible_answers)
    ON ballots TO flick_grafana_reader
    """

    # Tables that later migrations create are readable too.
    execute """
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO flick_grafana_reader
    """
  end

  def down do
    execute """
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE SELECT ON TABLES FROM flick_grafana_reader
    """

    # A table-level revoke also removes column grants.
    execute "REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM flick_grafana_reader"
    execute "REVOKE USAGE ON SCHEMA public FROM flick_grafana_reader"

    # Keep the role. Another database on the same server, such as flick_test,
    # may still grant it access, and Postgres refuses to drop it until none do.
  end
end
