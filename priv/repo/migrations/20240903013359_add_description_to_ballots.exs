defmodule Flick.Repo.Migrations.AddDescriptionToBallots do
  use Ecto.Migration

  def change do
    alter table(:ballots) do
      add :description, :text, null: true
    end
  end
end
