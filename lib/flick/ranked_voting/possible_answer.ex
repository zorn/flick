defmodule Flick.RankedVoting.PossibleAnswer do
  @moduledoc """
  One possible answer to a ballot's question, embedded in the ballot.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{id: Ecto.UUID.t(), value: String.t()}

  @type struct_t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :value, :string
  end

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(possible_answer, attrs) do
    possible_answer
    |> cast(attrs, [:value])
    |> update_change(:value, &String.trim/1)
    |> validate_required([:value])
  end
end
