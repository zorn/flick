defmodule Flick.Votes do
  @moduledoc """
  Provides functions related to capturing `Flick.Votes.Vote` entities related to
  a specific `Flick.Ballots.Ballot`.
  """

  alias Flick.Repo
  alias Flick.Votes.Vote

  @typep changeset :: Ecto.Changeset.t(Vote.t())

  @doc """
  Records a vote for the given `Flick.Ballots.Ballot` entity.
  """
  @spec record_vote(map()) :: {:ok, Vote.t()} | {:error, changeset()}
  def record_vote(attrs) do
    dbg(attrs)

    %Vote{}
    |> Vote.changeset(attrs)
    |> Repo.insert()
  end
end
