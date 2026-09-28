defmodule Flick.RankedVoting.PossibleAnswer do
  @moduledoc """
  One possible answer to a ballot's question, embedded in the ballot.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{id: Ecto.UUID.t(), value: String.t()}

  @type struct_t :: %__MODULE__{}

  @max_length 500

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :value, :string
  end

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(possible_answer, attrs) do
    possible_answer
    |> cast(attrs, [:value])
    # Ecto casts a cleared value to nil, which is a change for a saved answer.
    |> update_change(:value, &(&1 && String.trim(&1)))
    |> validate_required([:value])
    |> validate_length(:value, max: @max_length)
    |> validate_format(:value, ~r/\A[^\r\n]*\z/, message: "can't contain line breaks")
  end
end
