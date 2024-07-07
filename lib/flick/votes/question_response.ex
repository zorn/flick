defmodule Flick.Votes.QuestionResponse do
  @moduledoc """
  An embedded value that represents a collection of ranked answers relative to a
  question of a ballot.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Flick.Ballots.Question
  alias Flick.Votes.RankedAnswer

  @type t :: %__MODULE__{
          question_id: Question.id(),
          ranked_answers: [RankedAnswer.t()]
        }

  @type struct_t :: %__MODULE__{}

  embedded_schema do
    field :question_id, :binary_id
    embeds_many :ranked_answers, RankedAnswer, on_replace: :delete
  end

  @required_fields [:question_id]
  @optional_fields []

  # Maybe we could store a vitual field for the question so we can check it's answers during changeset? reference

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:ranked_answers,
      with: &RankedAnswer.changeset/2,
      sort_param: :ranked_answers_sort,
      drop_param: :ranked_answers_drop,
      required: true
    )
    |> validate_required(@required_fields)
  end
end
