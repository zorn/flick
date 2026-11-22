defmodule Flick.Repo.Migrations.CreateGrafanaReaderRole do
  @moduledoc """
  Creates `flick_grafana_reader`, the login role Grafana's Postgres data source
  uses. It may read only the columns the "Flick business" dashboard counts, and
  write nothing.

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

    # These settings guard against mistakes. The role can turn both off
    # itself, so the grants below are the real boundary.
    execute "ALTER ROLE flick_grafana_reader SET default_transaction_read_only = on"
    execute "ALTER ROLE flick_grafana_reader SET statement_timeout = '5s'"

    execute "GRANT USAGE ON SCHEMA public TO flick_grafana_reader"

    # Column grants keep user content and each ballot's secret, which gives
    # admin access in the app, out of Grafana. A panel that needs another
    # column needs a migration that grants it.
    execute "GRANT SELECT (id, inserted_at, published_at, closed_at) ON ballots TO flick_grafana_reader"
    execute "GRANT SELECT (id, ballot_id, inserted_at) ON votes TO flick_grafana_reader"
  end

  def down do
    execute "REVOKE SELECT ON ballots, votes FROM flick_grafana_reader"
    execute "REVOKE USAGE ON SCHEMA public FROM flick_grafana_reader"

    # Keep the role. Another database on the same server, such as flick_test,
    # may still grant it access, and Postgres refuses to drop it until none do.
  end
end
