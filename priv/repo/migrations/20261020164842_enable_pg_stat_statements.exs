defmodule Flick.Repo.Migrations.EnablePgStatStatements do
  use Ecto.Migration

  # LiveDashboard's Ecto Stats reads this extension for its "outliers" and
  # "calls" tabs. Its view raises an error unless the server preloads the
  # library, and local and CI Postgres do not. So the migration creates the
  # extension only where the library is preloaded, and Ecto Stats elsewhere
  # keeps reporting it as not enabled.
  def change do
    # The raw SQL touches no table, and the down step reverses it.
    # excellent_migrations:safety-assured-for-next-line raw_sql_executed
    execute """
            DO $$
            BEGIN
              IF 'pg_stat_statements' = ANY (
                string_to_array(replace(current_setting('shared_preload_libraries'), ' ', ''), ',')
              ) THEN
                CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
              END IF;
            END
            $$
            """,
            "DROP EXTENSION IF EXISTS pg_stat_statements"
  end
end
