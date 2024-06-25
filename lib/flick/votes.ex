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

  @doc """
  Returns an `Ecto.Changeset` representing changes to a `Flick.Votes.Vote` entity.
  """
  @spec change_vote(Vote.t() | Vote.struct_t(), map()) :: changeset()
  def change_vote(%Vote{} = vote, attrs) do
    Vote.changeset(vote, attrs)
  end
end
