defmodule Flick.Votes.Vote do
  @moduledoc """
  A vote is a collection of ranked answers for a `Flick.Ballots.Ballot` question.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Flick.Ballots.Ballot
  alias Flick.Votes.Answer

  @type id :: Ecto.UUID.t()

  @typedoc """
  A type for a persisted `Flick.Votes.Vote` entity.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          ballot_id: Ballot.id()
        }

  @type struct_t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    belongs_to :ballot, Ballot
    embeds_many :answers, Answer, on_replace: :delete
    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:ballot_id]
  @optional_fields []

  # TODO: Should the changelog of a vote require we have an answer for each question?
  # Q: If we accept a type `struct_t` would the changeset always be of type `t()`?
  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t())
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:answers,
      with: &Answer.changeset/2,
      sort_param: :answers_sort,
      drop_param: :answers_drop
    )
  end
end
