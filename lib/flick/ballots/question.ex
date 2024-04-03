defmodule Flick.Ballots.Question do
  use Ecto.Schema

  import Ecto.Changeset

  @type id :: Ecto.UUID.t()

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          title: String.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "questions" do
    field :title, :string
    field :ballot_id, :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:title]
  @optional_fields []

  def changeset(question, attrs) do
    question
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
