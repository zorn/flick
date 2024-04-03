defmodule Flick.Ballots.Ballot do
  @moduledoc """
  A ballot is a collection of questions.

  TOOD: We may need to keep track of a "published_at" and disallow changes to questions after that event.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Flick.Ballots.Question

  @type id :: Ecto.UUID.t()

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          title: String.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "ballots" do
    field :title, :string

    # We might want to revert this to an embeds_many if we want to keep the questions with the ballot. Questions probably should not have identiy unto themselves maybe.
    # has_many :questions, Question, on_replace: :delete

    embeds_many :questions, Question, on_replace: :delete

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:title]
  @optional_fields []

  def changeset(ballot, attrs) do
    ballot
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:questions, with: &Question.changeset/2)
  end
end
