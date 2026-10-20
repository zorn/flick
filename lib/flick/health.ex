defmodule Flick.Health do
  @moduledoc """
  Reports whether this instance can do its work. Render's health check reads it
  through `/health`.
  """

  use Boundary, top_level?: true, deps: [Flick.Repo]

  alias Flick.Repo

  # Render fails a check that takes longer than 5 seconds. A shorter timeout
  # frees the pool connection before Render gives up on a hung database.
  @timeout to_timeout(second: 2)

  @doc """
  Returns whether a trivial query reaches the database.
  """
  @spec database_reachable?() :: boolean()
  def database_reachable? do
    match?({:ok, _result}, Repo.query("SELECT 1", [], timeout: @timeout))
  end
end
