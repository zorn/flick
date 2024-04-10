defmodule Flick.Ballots do
  @moduledoc """
  Provides functions related to managing `Flick.Ballots.Ballot` entities.
  """

  alias Flick.Ballots.Ballot
  alias Flick.Repo

  @doc """
  Creates a new `Flick.Ballots.Ballot` entity with the given `title` and `questions`.
  """
  @spec create_ballot(String.t(), list(Question.t())) ::
          {:ok, Ballot.t()} | {:error, Ecto.Changeset.t(Ballot.t())}
  def create_ballot(title, questions) do
    # During creation changesets for the embedded questions will need to be made
    # and since changesets are based on a `Map` of changes, we'll convert the
    # incoming questions to `Map` values. We still want the expressiveness of
    # the `Question` type in the argument list, but will do the transform here
    # to allow the changeset to work as needed.
    questions_as_maps = Enum.map(questions, &Map.from_struct/1)

    attrs = %{
      title: title,
      questions: questions_as_maps
    }

    %Ballot{}
    |> Ballot.changeset(attrs)
    |> Repo.insert()
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
  @spec get_ballot!(Ballot.id()) :: Board.t()
  def get_ballot!(ballot_id) do
    Repo.get!(Ballot, ballot_id)
  end

  @doc """
  Fetches a `Flick.Ballots.Ballot` entity for the given id.
  """
  @spec fetch_ballot(Ballot.id()) :: {:ok, Ballot.t()} | :not_found
  def fetch_ballot(ballot_id) do
    case Repo.get(Ballot, ballot_id) do
      nil -> :not_found
      ballot -> {:ok, ballot}
    end
  end
end
