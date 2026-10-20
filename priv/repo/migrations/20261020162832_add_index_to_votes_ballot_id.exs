defmodule Flick.Repo.Migrations.AddIndexToVotesBallotId do
  use Ecto.Migration

  # A concurrent build does not lock `votes` against writes, but Postgres
  # refuses to run one inside a transaction.
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:votes, [:ballot_id], concurrently: true)
  end
end
