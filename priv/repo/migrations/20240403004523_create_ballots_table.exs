defmodule Flick.Repo.Migrations.CreateBallotsTable do
  use Ecto.Migration

  def change do
    create table(:ballots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_title, :text, null: false
      add :possible_answers, :text, null: false
      add :published_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end
  end
end
