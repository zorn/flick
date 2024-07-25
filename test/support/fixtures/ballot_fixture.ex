defmodule Support.Fixtures.BallotFixture do
  @moduledoc """
  Provides functions to allows tests to easily create and stage
  `Flick.RankedVoting.Ballot` entities for testing.
  """

  @doc """
  Returns a map of valid attributes for a `Flick.RankedVoting.Ballot` entity,
  allowing for the passed in attributes to override defaults.
  """
  def valid_ballot_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      question_title: "What day should have dinner?",
      possible_answers: "Monday, Tuesday, Wednesday, Thursday, Friday",
      published_at: nil
    })
  end

  @doc """
  Creates a `Flick.RankedVoting.Ballot` entity in the `Flick.Repo` for the passed in
  optional attributes.

  When not provided, all required attributes will be generated.
  """
  def ballot_fixture(attrs \\ %{}) do
    attrs = valid_ballot_attributes(attrs)
    {:ok, ballot} = Flick.RankedVoting.create_ballot(attrs)
    ballot
  end
end
