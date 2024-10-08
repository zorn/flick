defmodule Flick.Repo.Migrations.CreateBallotsTable do
  use Ecto.Migration

  def change do
    create table(:ballots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_title, :text, null: false
      add :url_slug, :string, null: false
      add :secret, :binary_id, null: false, default: fragment("gen_random_uuid()")
      add :possible_answers, :text, null: false
      add :published_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ballots, [:url_slug])
    create unique_index(:ballots, [:secret])
  end
end
