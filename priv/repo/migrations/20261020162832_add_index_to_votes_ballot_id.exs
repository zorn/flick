defmodule Flick.Repo.Migrations.AddIndexToVotesBallotId do
  use Ecto.Migration

  # A concurrent build does not block writes to `votes`. Postgres cannot run a
  # concurrent build inside a transaction.
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:votes, [:ballot_id], concurrently: true)
  end
end
