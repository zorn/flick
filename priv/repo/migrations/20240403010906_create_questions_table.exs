defmodule Flick.Repo.Migrations.CreateQuestionsTable do
  use Ecto.Migration

  def change do
    create table(:questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :text
      add :ballot_id, references(:ballots, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :timestamptz)
    end

    create index(:questions, [:ballot_id])
  end
end
