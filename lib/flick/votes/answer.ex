defmodule Flick.Votes.Answer do
  @moduledoc """
  TBD
  """

  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :question_id, :binary_id
    field :ranked_answer_ids, {:array, :binary_id}
  end

  # TODO: When capturing a vote, do we want to validate that all the supplied answer_ids match actual answers for the question in the ballot?
  # Maybe we could store a vitual field for the question so we can check it's answers during changeset? reference
end
