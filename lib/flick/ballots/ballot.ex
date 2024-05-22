defmodule Flick.Ballots.Ballot do
  @moduledoc """
  A ballot is a collection of questions.

  TODO: We may need to keep track of a "published_at" value and disallow changes
  to ballot and questions after it is considered published to help maintain data
  integrity.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Flick.Ballots.Question

  @type id :: Ecto.UUID.t()

  @typedoc """
  A type for a persisted `Flick.Ballots.Ballot` entity.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          title: String.t(),
          questions: list(Question.t())
        }

  @typedoc """
  A type for the base `Flick.Ballots.Ballot` struct.

  This type is helpful when you want to typespec a function that needs to accept
  a non-persisted `Flick.Ballots.Ballot` struct value.
  """
  @type struct_t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "ballots" do
    field :title, :string
    embeds_many :questions, Question, on_replace: :delete
    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:title]
  @optional_fields []

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(ballot, attrs) do
    ballot
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:questions,
      with: &Question.changeset/2,
      sort_param: :questions_sort,
      drop_param: :questions_drop
    )
  end
end
