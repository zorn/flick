defmodule Flick.Ballots do
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
end
