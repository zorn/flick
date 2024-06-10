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
    |> validate_possible_answers()
  end

  defp validate_possible_answers(changeset) do
    # Because we validated the value as `required` before this, we don't need to
    # concern ourselves with an empty list here.

    validate_change(changeset, :possible_answers, fn :possible_answers, updated_value ->
      answer_list = String.split(updated_value, ",")

      cond do
        String.contains?(updated_value, "\n") ->
          [possible_answers: "can't contain new lines"]

        Enum.any?(answer_list, &(&1 == "")) ->
          [possible_answers: "can't contain empty answers"]

        true ->
          []
      end
    end)
  end
end
