defmodule Flick.Health do
  @moduledoc """
  Reports whether this instance can do its work. Render's health check reads it
  through `/health`.
  """

  use Boundary, top_level?: true, deps: [Flick.Repo]

  alias Flick.Repo

  @doc """
  Returns whether a trivial query reaches the database.
  """
  @spec database_reachable?() :: boolean()
  def database_reachable? do
    match?({:ok, _result}, Repo.query("SELECT 1"))
  end
end
