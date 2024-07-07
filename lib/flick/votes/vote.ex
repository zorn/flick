defmodule Flick.Votes.Vote do
  @moduledoc """
  A vote is a collection of ranked answers for a `Flick.Ballots.Ballot` question.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import FlickWeb.Gettext

  alias Flick.Ballots.Ballot
  alias Flick.Votes.QuestionResponse

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
    embeds_many :question_responses, QuestionResponse, on_replace: :delete
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
    |> cast_embed(:question_responses,
      with: &QuestionResponse.changeset/2,
      sort_param: :question_responses_sort,
      drop_param: :question_responses_drop,
      required: true
    )
    |> validate_answers_are_present_in_ballot()
    |> validate_answers_question_uniqueness()
  end

  defp validate_answers_are_present_in_ballot(changeset) do
    validate_change(changeset, :question_responses, fn :question_responses,
                                                       new_question_responses ->
      ballot = Flick.Ballots.get_ballot!(get_field(changeset, :ballot_id))
      # For each of the question_response, make sure each ranked answer is
      # present in the possible answers for the question from the ballot.
      Enum.reduce(new_question_responses, [], fn changeset, acc ->
        question_id = get_field(changeset, :question_id)
        ranked_answers = get_field(changeset, :ranked_answers)
        question_from_ballot = Enum.find(ballot.questions, &(&1.id == question_id))

        case question_from_ballot do
          nil ->
            [question_responses: "question_id not found in ballot"]

          question ->
            possible_answers = String.split(question.possible_answers, ",", trim: true)
            possible_answers = Enum.map(possible_answers, &String.trim/1)

            invalid_answers =
              Enum.reject(ranked_answers, &Enum.member?(possible_answers, &1.value))

            if invalid_answers == [] do
              acc
            else
              error_label = ngettext("invalid answer", "invalid answers", length(invalid_answers))
              invalid_answers = Enum.map(invalid_answers, & &1.value)
              error_description = Enum.join(invalid_answers, ", ")
              [question_responses: "#{error_label}: #{error_description}"]
            end
        end
      end)
    end)
  end

  defp validate_answers_question_uniqueness(changeset) do
    validate_change(changeset, :question_responses, fn :question_responses,
                                                       new_question_responses ->
      question_ids =
        Enum.map(new_question_responses, fn changeset ->
          get_field(changeset, :question_id)
        end)

      if Enum.uniq(question_ids) == question_ids do
        []
      else
        [question_responses: "should not include duplicate question ids"]
      end
    end)
  end
end
