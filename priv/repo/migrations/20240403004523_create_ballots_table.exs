defmodule Flick.Repo.Migrations.CreateBallotsTable do
  use Ecto.Migration

  def change do
    create table(:ballots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :text

      # When we say `:map` here, ultimately that will become a JSONB column in the
      # database which will store the questions as an ordered list.
      add :questions, :map

      timestamps(type: :timestamptz)
    end
  end
end
