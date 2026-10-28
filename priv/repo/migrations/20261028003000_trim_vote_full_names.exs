defmodule Flick.Repo.Migrations.TrimVoteFullNames do
  @moduledoc """
  Trims surrounding whitespace from `votes.full_name`.
  `Flick.RankedVoting.Vote.create_changeset/3` now trims new votes the same way.
  See https://github.com/zorn/flick/issues/260.

  The trim runs in Elixir, not SQL. Postgres `trim()` strips only spaces.
  `String.trim/1` also strips tabs, newlines, and other Unicode whitespace.

  A name that trims to nothing becomes `NULL`, because `cast` turns a blank name
  into `nil`.
  """

  use Ecto.Migration

  def up do
    %{rows: rows} = repo().query!("SELECT id, full_name FROM votes WHERE full_name IS NOT NULL")

    for [id, full_name] <- rows, trimmed = String.trim(full_name), trimmed != full_name do
      repo().query!("UPDATE votes SET full_name = $1 WHERE id = $2", [
        if(trimmed == "", do: nil, else: trimmed),
        id
      ])
    end
  end

  # The original whitespace is not kept, so there is nothing to restore.
  def down, do: :ok
end
