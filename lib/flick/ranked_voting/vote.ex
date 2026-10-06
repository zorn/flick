defmodule Flick.RankedVoting.Vote do
  @moduledoc """
  A response to a `Flick.RankedVoting.Ballot`. A vote contains a collection of ranked
  answers for a ballot question.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.EmbedParams
  alias Flick.RankedVoting.RankedAnswer

  @type id :: Ecto.UUID.t()

  @typedoc """
  A type for a persisted `Flick.RankedVoting.Vote` entity.
  """
  @type t :: %__MODULE__{
          id: id(),
          ballot_id: Ballot.id(),
          weight: float(),
          full_name: String.t() | nil,
          ranked_answers: [RankedAnswer.t()]
        }

  @type struct_t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    belongs_to :ballot, Ballot
    field :weight, :float, default: 1.0
    field :full_name, :string
    embeds_many :ranked_answers, RankedAnswer, on_replace: :delete
    timestamps(type: :utc_datetime_usec)
  end

  @max_ranked_answers 5

  @doc """
  Returns the most answers a vote may rank, whatever the ballot's size.
  """
  @spec max_ranked_answers() :: pos_integer()
  def max_ranked_answers, do: @max_ranked_answers

  # Matches the `varchar(255)` column.
  @max_full_name_length 255

  @doc """
  Returns an `Ecto.Changeset` value appropriate for creating a
  `Flick.RankedVoting.Vote` entity.

  The `weight` field can not be set during creation and will default to `1.0`.
  """
  @spec create_changeset(struct_t(), map()) :: Changeset.t(struct_t())
  def create_changeset(vote, attrs) do
    attrs = EmbedParams.cap(attrs, "ranked_answers", @max_ranked_answers)

    vote
    |> cast(attrs, [:ballot_id, :full_name])
    |> validate_required([:ballot_id])
    # Postgres measures `varchar(255)` in code points, not graphemes.
    |> validate_length(:full_name, max: @max_full_name_length, count: :codepoints)
    |> cast_embed(:ranked_answers,
      with: &RankedAnswer.changeset/2,
      required: true
    )
    |> validate_ballot_is_published()
    |> validate_ranked_answer_count()
    |> validate_ranked_answers_are_present_in_ballot()
    |> validate_ranked_answers_are_not_duplicated()
    |> validate_first_ranked_answers_has_valid_value()
  end

  @doc """
  Returns an `Ecto.Changeset` value appropriate for updating a
  `Flick.RankedVoting.Vote` entity.

  Only `weight` can be updated.
  """
  @spec update_changeset(t(), map()) :: Changeset.t(t())
  def update_changeset(vote, attrs) do
    vote
    |> cast(attrs, [:weight])
    |> validate_required([:weight])
    |> validate_number(:weight, greater_than_or_equal_to: 0.0)
  end

  defp validate_ballot_is_published(changeset) do
    ballot = Flick.RankedVoting.get_ballot!(get_field(changeset, :ballot_id))

    validate_change(changeset, :ballot_id, fn :ballot_id, _ ->
      if is_nil(ballot.published_at) do
        [ballot_id: "ballot must be published"]
      else
        []
      end
    end)
  end

  defp validate_ranked_answer_count(changeset) do
    ballot = Flick.RankedVoting.get_ballot!(get_field(changeset, :ballot_id))
    allowed_count = Flick.RankedVoting.allowed_answer_count_for_ballot(ballot)

    if length(get_field(changeset, :ranked_answers)) > allowed_count do
      add_error(
        changeset,
        :ranked_answers,
        "must have at most %{count} answer(s)",
        count: allowed_count
      )
    else
      changeset
    end
  end

  defp validate_ranked_answers_are_present_in_ballot(changeset) do
    validate_change(changeset, :ranked_answers, fn :ranked_answers, new_ranked_answers ->
      # For each of the `ranked_answers`, make sure the answer value is present
      # in the ballot's possible answers.
      invalid_answers = invalid_answers(changeset, new_ranked_answers)

      if Enum.empty?(invalid_answers) do
        []
      else
        [
          ranked_answers:
            {"invalid answer(s): %{answers}",
             count: length(invalid_answers), answers: Enum.join(invalid_answers, ", ")}
        ]
      end
    end)
  end

  @spec invalid_answers(Changeset.t(t()), [Changeset.t(RankedAnswer.t())]) :: [String.t()]
  defp invalid_answers(changeset, new_ranked_answers) do
    ballot = Flick.RankedVoting.get_ballot!(get_field(changeset, :ballot_id))
    possible_answers = Ballot.possible_answer_values(ballot) ++ ["", nil]

    new_ranked_answers
    |> Enum.reduce([], fn changeset, acc ->
      ranked_answer_value = get_field(changeset, :value)

      if Enum.member?(possible_answers, ranked_answer_value) do
        acc
      else
        [ranked_answer_value] ++ acc
      end
    end)
    |> Enum.reverse()
  end

  defp validate_ranked_answers_are_not_duplicated(%Changeset{valid?: false} = changeset) do
    # If the changeset is already considered false we skip this validation,
    # since it does wholesale overwriting of the `ranked_answers` changeset list
    # and we don't want to overwrite the existing errors.
    changeset
  end

  defp validate_ranked_answers_are_not_duplicated(%Changeset{changes: changes} = changeset)
       when is_map_key(changes, :ranked_answers) do
    # For all the embedded changesets of `ranked_answers`, check if any are
    # known to be duplicates, and if so add a validation error to those
    # individual changesets.
    #
    # I'm not really proud of this solution, as it does a lot of manual map
    # manipulation. I welcome new suggestions. I do think it's important to have
    # the error be on the individual changeset, as those are more directly
    # presented to the user.
    ranked_answer_values = Enum.map(get_field(changeset, :ranked_answers), & &1.value)
    ranked_answer_frequencies = Enum.frequencies(ranked_answer_values)

    ranked_answer_changesets =
      Enum.map(changeset.changes.ranked_answers, fn changeset ->
        value = get_field(changeset, :value)

        if Map.get(ranked_answer_frequencies, value) > 1 and value not in ["", nil] do
          add_error(changeset, :value, "duplicates are not allowed")
        else
          changeset
        end
      end)

    new_changes = Map.put(changeset.changes, :ranked_answers, ranked_answer_changesets)
    new_changes_are_valid = Enum.all?(ranked_answer_changesets, & &1.valid?)

    changeset
    |> Map.put(:changes, new_changes)
    |> Map.put(:valid?, new_changes_are_valid)
  end

  defp validate_ranked_answers_are_not_duplicated(changeset) do
    changeset
  end

  defp validate_first_ranked_answers_has_valid_value(%Changeset{valid?: false} = changeset) do
    changeset
  end

  # FIXME: Refactor to reduce complexity.
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp validate_first_ranked_answers_has_valid_value(%Changeset{changes: changes} = changeset)
       when is_map_key(changes, :ranked_answers) do
    ranked_answer_changesets =
      Enum.map(Enum.with_index(changeset.changes.ranked_answers), fn {changeset, index} ->
        with 0 <- index,
             value <- get_field(changeset, :value),
             true <- value in ["", nil] do
          add_error(changeset, :value, "can't be blank")
        else
          _ -> changeset
        end
      end)

    new_changes = Map.put(changeset.changes, :ranked_answers, ranked_answer_changesets)
    new_changes_are_valid = Enum.all?(ranked_answer_changesets, & &1.valid?)

    changeset
    |> Map.put(:changes, new_changes)
    |> Map.put(:valid?, new_changes_are_valid)
  end

  defp validate_first_ranked_answers_has_valid_value(changeset) do
    changeset
  end
end
