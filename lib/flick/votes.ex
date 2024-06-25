defmodule Flick.Votes do
  @moduledoc """
  Provides functions related to capturing `Flick.Votes.Vote` entities related to
  a specific `Flick.Ballots.Ballot`.
  """

  alias Flick.Ballots.Ballot
  alias Flick.Repo
  alias Flick.Votes.Vote

  @typep changeset :: Ecto.Changeset.t(Vote.t())

  @doc """
  Records a vote for the given `Flick.Ballots.Ballot` entity.
  """
  @spec record_vote(Ballot.t(), map()) :: {:ok, Vote.t()} | {:error, changeset()}
  def record_vote(ballot, attrs) do
    attrs = Map.put(attrs, "ballot_id", ballot.id)

    %Vote{}
    |> Vote.changeset(attrs)
    |> Repo.insert()
  end
end
