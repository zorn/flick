defmodule Flick.Ballots.Question do
  @moduledoc """
  A prompt for the user, presented inside a ballot, that requests a response.
  """

  use Ecto.Schema

  import Ecto.Changeset

  # The Ecto implementation of `embeds_many` will store a `id` value for each
  # question, but that should not be considered a public long-lived identity,
  # and so you won't find it in the typespec below.
  @type t :: %__MODULE__{
          title: String.t(),
          possible_answers: String.t()
        }

  @type id :: Ecto.UUID.t()

  embedded_schema do
    field :title, :string
    field :possible_answers, :string
  end

  @required_fields [:title, :possible_answers]
  @optional_fields []

  def changeset(question, attrs) do
    question
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
