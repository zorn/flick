defmodule Flick.Repo.Migrations.CreateBallotsTable do
  use Ecto.Migration

  def change do
    create table(:ballots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :text, null: false
      add :published_at, :utc_datetime_usec

      # When we say `:map` here, ultimately that will become a JSONB column in the
      # database which will store the questions as an ordered list.
      add :questions, :map, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
