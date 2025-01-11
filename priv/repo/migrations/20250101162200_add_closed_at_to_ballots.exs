defmodule Flick.Repo.Migrations.AddClosedAtToBallots do
  use Ecto.Migration

  def change do
    alter table(:ballots) do
      add :closed_at, :utc_datetime_usec, null: true
    end
  end
end
