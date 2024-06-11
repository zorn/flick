# defmodule Flick.Ballots.PublishedAnswer do
#   @moduledoc """
#   An answer with identity, created when a ballot is published.
#   """

#   use Ecto.Schema

#   import Ecto.Changeset

#   @type id :: Ecto.UUID.t()

#   @primary_key {:id, :binary_id, autogenerate: true}
#   schema "published_answer" do
#     field :title, :string
#     field :published_at, :utc_datetime_usec
#     embeds_many :questions, Question, on_replace: :delete
#     timestamps(type: :utc_datetime_usec)
#   end

# end
