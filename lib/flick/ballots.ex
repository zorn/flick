defmodule Flick.Ballots do
  @moduledoc """
  Provides functions related to managing `Flick.Ballots.Ballot` entities.
  """

  alias Flick.Ballots.Ballot
  alias Flick.Repo

  @typep changeset :: Ecto.Changeset.t(Ballot.t())

  @doc """
  Creates a new `Flick.Ballots.Ballot` entity with the given `title` and `questions`.
  """
  @spec create_ballot(map()) :: {:ok, Ballot.t()} | {:error, changeset()}
  def create_ballot(attrs) do
    %Ballot{}
    |> change_ballot(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the given `Flick.Ballots.Ballot` entity with the given attributes.
  """
  @spec update_ballot(Ballot.t(), map()) :: {:ok, Ballot.t()} | {:error, changeset()}
  def update_ballot(ballot, attrs) do
    ballot
    |> change_ballot(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a list of all `Flick.Ballots.Ballot` entities.
  """
  def list_ballots() do
    # TODO: Currently there is no expectation regarding the order of the
    # returned list. We should add something.

    Repo.all(Ballot)
  end

  @doc """
  Returns a `Flick.Ballots.Ballot` entity for the given id.

  Raises `Ecto.NoResultsError` if no entity was found.
  """
  @spec get_ballot!(Ballot.id()) :: Ballot.t()
  def get_ballot!(ballot_id) do
    Repo.get!(Ballot, ballot_id)
  end

  @doc """
  Fetches a `Flick.Ballots.Ballot` entity for the given id.
  """
  @spec fetch_ballot(Ballot.id()) :: {:ok, Ballot.t()} | :ballot_not_found
  def fetch_ballot(ballot_id) do
    case Repo.get(Ballot, ballot_id) do
      nil -> :ballot_not_found
      ballot -> {:ok, ballot}
    end
  end

  @doc """
  Returns an `Ecto.Changeset` representing changes to a `Flick.Ballots.Ballot` entity.
  """
  @spec change_ballot(Ballot.t() | Ballot.struct_t(), map()) :: changeset()
  def change_ballot(ballot, attrs) do
    Ballot.changeset(ballot, attrs)
  end
end
