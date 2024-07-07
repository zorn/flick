defmodule Flick.Votes.RankedAnswer do
  @moduledoc """
  An embedded value that represents a ranked answer to a question of a ballot.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          value: String.t()
        }

  @type struct_t :: %__MODULE__{}

  embedded_schema do
    # Maybe use a virtual field for possible values?
    field :value, :string
  end

  @required_fields [:value]
  @optional_fields []

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(ranked_answer, attrs) do
    ranked_answer
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
