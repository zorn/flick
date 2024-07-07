defmodule Flick.Ballots.Ballot do
  @moduledoc """
  A prompt that will be presented to the user, asking them to provide a ranked
  vote of answers to help make a group decision.

  During creation a ballot can be edited over time. When ready a ballot is
  published, preventing future editing, and allowing users to vote.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type id :: Ecto.UUID.t()

  @typedoc """
  A type for a persisted `Flick.Ballots.Ballot` entity.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          question_title: String.t(),
          possible_answers: String.t(),
          published_at: DateTime.t() | nil
        }

  @typedoc """
  A type for the empty `Flick.Ballots.Ballot` struct.

  This type is helpful when you want to typespec a function that needs to accept
  a non-persisted `Flick.Ballots.Ballot` struct value.
  """
  @type struct_t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ballots" do
    field :question_title, :string
    field :possible_answers, :string
    field :published_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:question_title, :possible_answers]
  @optional_fields [:published_at]

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t()) | Ecto.Changeset.t(struct_t())
  def changeset(ballot, attrs) do
    ballot
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_possible_answers()
  end

  def possible_answers_as_list(possible_answers) when is_binary(possible_answers) do
    possible_answers
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp validate_possible_answers(changeset) do
    # Because we validated the value as `required` before this, we don't need to
    # concern ourselves with an empty list here.
    validate_change(changeset, :possible_answers, fn :possible_answers, updated_value ->
      answer_list = possible_answers_as_list(updated_value)

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
