defmodule Flick.RankedVoting.Vote do
  @moduledoc """
  A response to a `Flick.RankedVoting.Ballot`. A vote contains a collection of ranked
  answers for a ballot question.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import FlickWeb.Gettext

  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.RankedAnswer

  @type id :: Ecto.UUID.t()

  @typedoc """
  A type for a persisted `Flick.RankedVoting.Vote` entity.
  """
  @type t :: %__MODULE__{
          id: id(),
          ballot_id: Ballot.id(),
          ranked_answers: [RankedAnswer.t()]
        }

  @type struct_t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    belongs_to :ballot, Ballot
    embeds_many :ranked_answers, RankedAnswer, on_replace: :delete
    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:ballot_id]
  @optional_fields []

  @spec changeset(t() | struct_t(), map()) ::
          Ecto.Changeset.t(t()) | Ecto.Changeset.t(struct_t())
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:ranked_answers,
      with: &RankedAnswer.changeset/2,
      required: true
    )
    |> validate_ranked_answers_are_present_in_ballot()
    |> validate_ranked_answers_are_not_duplicated()
    |> validate_first_ranked_answers_has_valid_value()
  end

  defp validate_ranked_answers_are_present_in_ballot(changeset) do
    ballot = Flick.RankedVoting.get_ballot!(get_field(changeset, :ballot_id))
    possible_answers = Ballot.possible_answers_as_list(ballot.possible_answers) ++ ["", nil]

    validate_change(changeset, :ranked_answers, fn :ranked_answers, new_ranked_answers ->
      # For each of the `ranked_answers`, make sure the answer value is present
      # in the ballot's possible answers.
      invalid_answers =
        Enum.reduce(new_ranked_answers, [], fn changeset, acc ->
          ranked_answer_value = get_field(changeset, :value)

          if Enum.member?(possible_answers, ranked_answer_value) do
            acc
          else
            acc ++ [ranked_answer_value]
          end
        end)

      if length(invalid_answers) > 0 do
        error_label = ngettext("invalid answer", "invalid answers", length(invalid_answers))
        [ranked_answers: "#{error_label}: #{Enum.join(invalid_answers, ", ")}"]
      else
        []
      end
    end)
  end

  defp validate_ranked_answers_are_not_duplicated(%Ecto.Changeset{valid?: false} = changeset) do
    # If the changeset is already considered false we skip this validation,
    # since it does wholesale overwriting of the `ranked_answers` changeset list
    # and we don't want to overwrite the existing errors.
    changeset
  end

  defp validate_ranked_answers_are_not_duplicated(%Ecto.Changeset{changes: changes} = changeset)
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
          add_error(changeset, :value, gettext("answers must not be duplicated"))
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

  defp validate_first_ranked_answers_has_valid_value(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  defp validate_first_ranked_answers_has_valid_value(
         %Ecto.Changeset{changes: changes} = changeset
       )
       when is_map_key(changes, :ranked_answers) do
    ranked_answer_changesets =
      Enum.map(Enum.with_index(changeset.changes.ranked_answers), fn {changeset, index} ->
        if index == 0 do
          value = get_field(changeset, :value)

          if value in ["", nil] do
            add_error(changeset, :value, gettext("first answer is required"))
          else
            changeset
          end
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

  defp validate_first_ranked_answers_has_valid_value(changeset) do
    changeset
  end
end
