defmodule Flick.Ballots.AnswerOption do
  @moduledoc """
  A possible response to a question on a ballot.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          title: String.t()
        }

  embedded_schema do
    field :title, :string
  end

  @required_fields [:title]
  @optional_fields []

  def changeset(answer_option, attrs) do
    answer_option
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
