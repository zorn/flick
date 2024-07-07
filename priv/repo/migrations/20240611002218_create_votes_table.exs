defmodule Flick.Repo.Migrations.CreateVotesTable do
  use Ecto.Migration

  def change do
    create table(:votes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ballot_id, references(:ballots, type: :binary_id, on_delete: :delete_all), null: false
      add :question_responses, :map, null: false
      timestamps(type: :utc_datetime_usec)
    end
  end
end
