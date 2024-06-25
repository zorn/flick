defmodule Flick.Votes.Answer do
  @moduledoc """
  A collection of ranked answers to a question of a ballot.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Flick.Ballots.Question

  @type t :: %__MODULE__{
          question_id: Question.id(),
          ranked_answers: [String.t()]
        }

  @type struct_t :: %__MODULE__{}

  embedded_schema do
    field :ballot_id, :binary_id, virtual: true
    field :question_id, :binary_id

    # TODO: While we collapsed the inner embed in ballot, I think for a vote we need to make this a seperate embeded_many so that we can do multiple `inputs_for` when rendering the view. Each ranked answer is just going to be be a value
    field :ranked_answers, {:array, :string}
  end

  @required_fields [:question_id, :ranked_answers]
  @optional_fields []

  # Maybe we could store a vitual field for the question so we can check it's answers during changeset? reference

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
