defmodule Flick.RankedVoting.Ballot do
  @moduledoc """
  A prompt that will be presented to the user, asking them to provide a ranked
  vote of answers to help make a group decision.

  During creation a ballot can be edited over time. When ready a ballot is
  published, preventing future editing, and allowing users to vote.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Flick.RankedVoting.PossibleAnswer

  @type id :: Ecto.UUID.t()

  @typedoc """
  A type for a persisted `Flick.RankedVoting.Ballot` entity.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          question_title: String.t(),
          description: String.t() | nil,
          url_slug: String.t(),
          secret: Ecto.UUID.t(),
          possible_answers: [PossibleAnswer.t()],
          published_at: DateTime.t() | nil,
          closed_at: DateTime.t() | nil
        }

  @typedoc """
  A changeset for a `Flick.RankedVoting.Ballot` entity.
  """
  @type changeset :: Ecto.Changeset.t(t())

  @typedoc """
  A type for the empty `Flick.RankedVoting.Ballot` struct.

  This type is helpful when you want to typespec a function that needs to accept
  a non-persisted `Flick.RankedVoting.Ballot` struct value.
  """
  @type struct_t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ballots" do
    field :question_title, :string
    field :description, :string, default: nil
    field :url_slug, :string
    field :secret, :binary_id, read_after_writes: true
    embeds_many :possible_answers, PossibleAnswer, on_replace: :delete
    field :published_at, :utc_datetime_usec
    field :closed_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:question_title, :url_slug]

  # With intent, we do not allow `published_at` or `closed_at` to be set inside
  # a normal changeset. Instead look to the
  # `Flick.RankedVoting.publish_ballot/2` and
  # `Flick.RankedVoting.close_ballot/2` to perform those updates.
  @optional_fields [:description]

  @min_possible_answers 2

  @doc """
  Returns the fewest possible answers a ballot may have.
  """
  @spec min_possible_answers() :: pos_integer()
  def min_possible_answers, do: @min_possible_answers

  @spec changeset(t() | struct_t(), map()) :: Ecto.Changeset.t(t()) | Ecto.Changeset.t(struct_t())
  def changeset(ballot, attrs) do
    ballot
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:possible_answers,
      sort_param: :possible_answers_sort,
      drop_param: :possible_answers_drop
    )
    |> validate_required(@required_fields)
    |> validate_possible_answer_count()
    |> validate_format(:url_slug, ~r/^[a-zA-Z0-9-]+$/,
      message: "can only contain letters, numbers, and hyphens"
    )
    |> validate_length(:url_slug, min: 3, max: 255)
    |> unique_constraint(:url_slug)
  end

  defp validate_possible_answer_count(changeset) do
    if length(get_field(changeset, :possible_answers)) < @min_possible_answers do
      add_error(changeset, :possible_answers, "must have at least two answers")
    else
      changeset
    end
  end

  @doc """
  Removes possible answers left blank from the given ballot attributes.

  The editor offers empty rows to type into, so saving drops the ones left
  blank. `changeset/2` doesn't call this, or blank rows would vanish from the
  form while the ballot owner is still typing.
  """
  @spec drop_blank_possible_answers(map()) :: map()
  def drop_blank_possible_answers(%{"possible_answers" => answers} = attrs)
      when is_map(answers) do
    blank_indexes = for {index, answer} <- answers, blank_answer?(answer), do: index
    Map.update(attrs, "possible_answers_drop", blank_indexes, &(&1 ++ blank_indexes))
  end

  def drop_blank_possible_answers(attrs) do
    Enum.into(attrs, %{}, fn
      {key, answers} when key in [:possible_answers, "possible_answers"] and is_list(answers) ->
        {key, Enum.reject(answers, &blank_answer?/1)}

      pair ->
        pair
    end)
  end

  defp blank_answer?(%{value: value}), do: blank_value?(value)
  defp blank_answer?(%{"value" => value}), do: blank_value?(value)
  defp blank_answer?(_answer), do: true

  defp blank_value?(value), do: value |> to_string() |> String.trim() == ""

  @doc """
  Returns the values of the ballot's possible answers in the order voters see them.
  """
  @spec answer_values(t()) :: [String.t()]
  def answer_values(%__MODULE__{possible_answers: possible_answers}) do
    Enum.map(possible_answers, & &1.value)
  end
end
