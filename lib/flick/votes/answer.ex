defmodule Flick.Votes.Answer do
  @moduledoc """
  TBD
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Flick.Ballots.Question

  # The Ecto implementation of `embeds_many` will store a `id` value for each
  # question, but that should not be considered a public long-lived identity,
  # and so you won't find it in the typespec below.
  @type t :: %__MODULE__{
          question_id: Question.id(),
          ranked_answer_ids: []
        }

  @type struct_t :: %__MODULE__{}

  embedded_schema do
    field :question_id, :binary_id
    field :ranked_answer_ids, {:array, :binary_id}
  end

  @required_fields [:question_id, :ranked_answer_ids]
  @optional_fields []

  # TODO: When capturing a vote, do we want to validate that all the supplied answer_ids match actual answers for the question in the ballot?
  # Maybe we could store a vitual field for the question so we can check it's answers during changeset? reference

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
