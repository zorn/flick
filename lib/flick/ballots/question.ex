defmodule Flick.Ballots.Question do
  @moduledoc """
  A prompt for the user, presented inside a ballot, that requests a response.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Flick.Ballots.AnswerOption

  # The Ecto implementation of `embeds_many` will store a `id` value for each
  # question, but that should not be considered a public long-lived identity,
  # and so you won't find it in the typespec below.
  @type t :: %__MODULE__{
          title: String.t()
        }

  embedded_schema do
    field :title, :string
    embeds_many :answer_options, AnswerOption, on_replace: :delete
  end

  @required_fields [:title]
  @optional_fields []

  def changeset(question, attrs) do
    question
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:answer_options,
      with: &AnswerOption.changeset/2,
      sort_param: :answer_options_sort,
      drop_param: :answer_options_drop
    )
  end
end
