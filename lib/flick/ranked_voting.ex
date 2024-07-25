defmodule Flick.RankedVoting do
  @moduledoc """
  Provides functions related to managing `Flick.RankedVoting.Ballot` entities.
  """

  alias Flick.RankedVoting.Ballot
  alias Flick.Repo

  @typep changeset :: Ecto.Changeset.t(Ballot.t())

  @doc """
  Creates a new `Flick.RankedVoting.Ballot` entity with the given `title` and `questions`.
  """
  @spec create_ballot(map()) :: {:ok, Ballot.t()} | {:error, changeset()}
  def create_ballot(attrs) when is_map(attrs) do
    %Ballot{}
    |> change_ballot(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the given `Flick.RankedVoting.Ballot` entity with the given attributes.

  If the `Flick.RankedVoting.Ballot` has already been published, an error is returned.
  """
  @spec update_ballot(Ballot.t(), map()) ::
          {:ok, Ballot.t()}
          | {:error, changeset()}
          | {:error, :can_not_update_published_ballot}
  def update_ballot(%Ballot{published_at: published_at}, _attrs)
      when not is_nil(published_at) do
    {:error, :can_not_update_published_ballot}
  end

  def update_ballot(%Ballot{published_at: nil} = ballot, attrs) do
    ballot
    |> change_ballot(attrs)
    |> Repo.update()
  end

  @doc """
  Publishes the given `Flick.RankedVoting.Ballot` entity.

  Once a `Flick.RankedVoting.Ballot` entity is published, it can no longer be updated.
  Only a published ballot can be voted on.
  """
  @spec publish_ballot(Ballot.t(), DateTime.t()) ::
          {:ok, Ballot.t()}
          | {:error, changeset()}
          | {:error, :ballot_already_published}
  def publish_ballot(ballot, published_at \\ DateTime.utc_now())

  def publish_ballot(%Ballot{published_at: published_at}, _published_at)
      when not is_nil(published_at) do
    {:error, :ballot_already_published}
  end

  def publish_ballot(%Ballot{} = ballot, published_at) do
    ballot
    |> change_ballot(%{published_at: published_at})
    |> Repo.update()
  end

  @doc """
  Returns a list of all `Flick.RankedVoting.Ballot` entities.
  """
  @spec list_ballots() :: [Ballot.t()]
  def list_ballots() do
    # TODO: Currently there is no expectation regarding the order of the
    # returned list. We should add something.

    Repo.all(Ballot)
  end

  @doc """
  Returns a `Flick.RankedVoting.Ballot` entity for the given id.

  Raises `Ecto.NoResultsError` if no entity was found.
  """
  @spec get_ballot!(Ballot.id()) :: Ballot.t()
  def get_ballot!(ballot_id) do
    Repo.get!(Ballot, ballot_id)
  end

  @doc """
  Fetches a `Flick.RankedVoting.Ballot` entity for the given id.
  """
  @spec fetch_ballot(Ballot.id()) :: {:ok, Ballot.t()} | {:error, :ballot_not_found}
  def fetch_ballot(ballot_id) do
    case Repo.get(Ballot, ballot_id) do
      nil -> {:error, :ballot_not_found}
      ballot -> {:ok, ballot}
    end
  end

  @doc """
  Returns an `Ecto.Changeset` representing changes to a `Flick.RankedVoting.Ballot` entity.
  """
  @spec change_ballot(Ballot.t() | Ballot.struct_t(), map()) :: changeset()
  def change_ballot(%Ballot{} = ballot, attrs) do
    Ballot.changeset(ballot, attrs)
  end
end
