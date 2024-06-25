defmodule Flick.Votes.Vote do
  @moduledoc """
  A vote is a collection of ranked answers for a `Flick.Ballots.Ballot` question.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import FlickWeb.Gettext

  alias Flick.Ballots.Ballot
  alias Flick.Votes.Answer

  @type id :: Ecto.UUID.t()

  @typedoc """
  A type for a persisted `Flick.Votes.Vote` entity.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          ballot_id: Ballot.id()
        }

  @type struct_t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    belongs_to :ballot, Ballot
    embeds_many :answers, Answer, on_replace: :delete
    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:ballot_id]
  @optional_fields []

  # TODO: Should the changelog of a vote require we have an answer for each question?
  # Q: If we accept a type `struct_t` would the changeset always be of type `t()`?
  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:answers,
      with: &Answer.changeset/2,
      sort_param: :answers_sort,
      drop_param: :answers_drop,
      required: true
    )
    |> validate_answers_are_present_in_ballot()
    |> validate_answers_question_uniqueness()
  end

  defp validate_answers_are_present_in_ballot(changeset) do
    validate_change(changeset, :answers, fn :answers, new_answers ->
      ballot = Flick.Ballots.get_ballot!(get_field(changeset, :ballot_id))
      # For each of the answers, make sure each ranked answer is present in the
      # possible answers for the question from the ballot.
      Enum.reduce(new_answers, [], fn changeset, acc ->
        question_id = get_field(changeset, :question_id)
        ranked_answers = get_field(changeset, :ranked_answers)
        question_from_ballot = Enum.find(ballot.questions, &(&1.id == question_id))

        case question_from_ballot do
          nil ->
            [answers: "question_id not found in ballot"]

          question ->
            possible_answers = String.split(question.possible_answers, ",")
            invalid_answers = Enum.reject(ranked_answers, &Enum.member?(possible_answers, &1))

            if invalid_answers == [] do
              acc
            else
              error_label = ngettext("invalid answer", "invalid answers", length(invalid_answers))
              error_description = Enum.join(invalid_answers, ", ")
              [answers: "#{error_label}: #{error_description}"]
            end
        end
      end)
    end)
  end

  defp validate_answers_question_uniqueness(changeset) do
    validate_change(changeset, :answers, fn :answers, new_answers ->
      question_ids =
        Enum.map(new_answers, fn changeset ->
          get_field(changeset, :question_id)
        end)

      if Enum.uniq(question_ids) == question_ids do
        []
      else
        [answers: "should not include duplicate question ids"]
      end
    end)
  end
end
