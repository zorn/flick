defmodule Flick.Repo.Migrations.ConvertPossibleAnswersToEmbeds do
  @moduledoc """
  Converts `ballots.possible_answers` from a comma-separated string to a jsonb
  array of `Flick.RankedVoting.PossibleAnswer` embeds, in place.

  Votes reference answers by their text, so the split below must match the one
  the old `Ballot.possible_answers_as_list/1` performed. It is copied here rather
  than called, because that function is removed alongside this migration. See
  https://github.com/zorn/flick/issues/204.
  """

  use Ecto.Migration

  def up do
    alter table(:ballots) do
      add :possible_answers_embeds, :jsonb
    end

    flush()

    # Some published and closed ballots already have duplicate answers. They
    # are carried over unchanged; see Decision 5.
    ballots =
      for [id, possible_answers] <- rows("SELECT id, possible_answers FROM ballots") do
        {id, split(possible_answers)}
      end

    for {id, answers} <- ballots do
      embeds = Enum.map(answers, &%{"id" => Ecto.UUID.generate(), "value" => &1})

      repo().query!("UPDATE ballots SET possible_answers_embeds = $1 WHERE id = $2", [
        embeds,
        id
      ])
    end

    alter table(:ballots) do
      remove :possible_answers
    end

    rename table(:ballots), :possible_answers_embeds, to: :possible_answers
    execute "ALTER TABLE ballots ALTER COLUMN possible_answers SET NOT NULL"
  end

  def down do
    alter table(:ballots) do
      add :possible_answers_text, :text
    end

    flush()

    for [id, embeds] <- rows("SELECT id, possible_answers FROM ballots") do
      values = Enum.map(embeds, & &1["value"])

      # Rejoining an answer that contains a comma would silently split it in two.
      if Enum.any?(values, &String.contains?(&1, ",")) do
        raise "ballot #{Ecto.UUID.cast!(id)} has an answer containing a comma; cannot roll back"
      end

      repo().query!("UPDATE ballots SET possible_answers_text = $1 WHERE id = $2", [
        Enum.join(values, ", "),
        id
      ])
    end

    alter table(:ballots) do
      remove :possible_answers
    end

    rename table(:ballots), :possible_answers_text, to: :possible_answers
    execute "ALTER TABLE ballots ALTER COLUMN possible_answers SET NOT NULL"
  end

  defp rows(sql), do: repo().query!(sql).rows

  defp split(possible_answers) do
    possible_answers
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end
end
