defmodule Flick.Votes.Vote do
  @moduledoc """
  A response to a `Flick.Ballots.Ballot`. A vote contains a collection of ranked
  answers for a ballot question.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import FlickWeb.Gettext

  # Q: I think I should combine these contexts.
  alias Flick.Ballots.Ballot
  alias Flick.Votes.RankedAnswer

  @type id :: Ecto.UUID.t()

  @typedoc """
  A type for a persisted `Flick.Votes.Vote` entity.
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

  # Q: If we accept a type `struct_t` would the changeset always be of type `t()`?
  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:ranked_answers,
      with: &RankedAnswer.changeset/2,
      required: true
    )
    |> validate_ranked_answers_are_present_in_ballot()
  end

  defp validate_ranked_answers_are_present_in_ballot(changeset) do
    validate_change(changeset, :ranked_answers, fn :ranked_answers, new_ranked_answers ->
      ballot = Flick.Ballots.get_ballot!(get_field(changeset, :ballot_id))
      possible_answers = Ballot.possible_answers_as_list(ballot.possible_answers)

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
end
