defmodule Flick.Votes do
  @moduledoc """
  Provides functions related to capturing `Flick.RankedVoting.Vote` entities related to
  a specific `Flick.RankedVoting.Ballot`.
  """

  alias Flick.RankedVoting.Ballot
  alias Flick.Repo
  alias Flick.RankedVoting.Vote

  @typep changeset :: Ecto.Changeset.t(Vote.t())

  @doc """
  Records a vote for the given `Flick.RankedVoting.Ballot` entity.
  """
  @spec record_vote(Ballot.t(), map()) :: {:ok, Vote.t()} | {:error, changeset()}
  def record_vote(ballot, attrs) do
    attrs = Map.put(attrs, "ballot_id", ballot.id)

    %Vote{}
    |> Vote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `Ecto.Changeset` representing changes to a `Flick.RankedVoting.Vote`
  entity.

  ## Options

  * `:action` - An optional atom applied to the changeset, useful for forms that
    look to a changeset's action to influence form behavior.
  """
  @spec change_vote(Vote.t() | Vote.struct_t(), map()) :: changeset()
  def change_vote(%Vote{} = vote, attrs, opts \\ []) do
    opts = Keyword.validate!(opts, action: nil)
    changeset = Vote.changeset(vote, attrs)

    if opts[:action] do
      Map.put(changeset, :action, opts[:action])
    else
      changeset
    end
  end
end
