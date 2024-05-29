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

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "votes" do
    field :ballot_id, :binary_id
    embeds_many :answers, Answer, on_replace: :delete
    timestamps(type: :utc_datetime_usec)
  end

  # TODO: Should the changelog of a vote require we have an answer for each question?
end
