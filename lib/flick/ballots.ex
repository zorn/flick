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
    attrs = %{
      title: title,
      questions: questions
    }

    %Ballot{}
    |> change_ballot(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the given `Flick.Ballots.Ballot` entity with the given attributes.
  """
  # TODO: I wish this map were more specific.
  @spec update_ballot(Ballot.t(), map()) ::
          {:ok, Ballot.t()} | {:error, Ecto.Changeset.t(Ballot.t())}
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

  @typedoc """
  The expected shape of the attribute maps when creating a
  `Flick.Ballots.Ballot` changeset.
  """
  @type change_ballot_attrs :: %{
          optional(:title) => String.t(),
          optional(:questions) => list(Question.t())
        }

  @doc """
  Returns an `Ecto.Changeset` representing changes to a `Flick.Ballots.Ballot` entity.
  """
  @spec change_ballot(Ballot.t() | Ballot.struct_t(), change_ballot_attrs()) ::
          Ecto.Changeset.t(Ballot.t())
  def change_ballot(ballot, attrs) do
    # attrs = convert_questions(attrs)
    Ballot.changeset(ballot, attrs)
  end

  @spec convert_questions(change_ballot_attrs()) :: map()
  defp convert_questions(%{questions: questions} = attrs) do
    # The internal `Ballot.changeset/2` function needs the questions values in
    # the `attrs` as raw map values for `embed_many` reasons.
    %{attrs | questions: Enum.map(questions, &Map.from_struct/1)}
  end

  defp convert_questions(attrs), do: attrs
end
