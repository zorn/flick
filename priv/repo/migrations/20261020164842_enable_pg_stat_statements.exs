defmodule Flick.Repo.Migrations.EnablePgStatStatements do
  use Ecto.Migration

  # LiveDashboard's Ecto Stats needs this extension for its "outliers" and
  # "calls" tabs. The extension's view raises an error unless the server
  # preloads the library. Local and CI Postgres do not preload it.
  #
  # Only a superuser can read `shared_preload_libraries`, so the block creates
  # the extension and reads the view once. On an error, the block rolls back
  # and leaves no extension. A diagnostics extension must never block a deploy.
  def change do
    # The raw SQL touches no table. The down step reverses it.
    # excellent_migrations:safety-assured-for-next-line raw_sql_executed
    execute """
            DO $$
            BEGIN
              CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
              PERFORM 1 FROM pg_stat_statements LIMIT 1;
            EXCEPTION
              WHEN OTHERS THEN
                RAISE NOTICE 'pg_stat_statements skipped: %', SQLERRM;
            END
            $$
            """,
            "DROP EXTENSION IF EXISTS pg_stat_statements"
  end
end
