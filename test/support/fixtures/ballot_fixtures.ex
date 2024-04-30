defmodule Support.Fixtures.BallotFixtures do
  @moduledoc """
  Provides functions to allows tests to easily create and stage
  `Flick.Ballots.Ballot` entities for testing.
  """

  @doc """
  Generates a unique ballot title.
  """
  def unique_ballot_title, do: "some-ballot-#{System.unique_integer()}"

  @doc """
  Returns a map of valid attributes for a `Flick.Ballots.Ballot` entity,
  allowing for the passed in attributes to override defaults.
  """
  def valid_ballot_attributes(attrs \\ %{}) do
    questions =
      [
        Support.Fixtures.QuestionFixture.question_fixture(),
        Support.Fixtures.QuestionFixture.question_fixture()
      ]
      |> Enum.map(&Map.from_struct/1)

    Enum.into(attrs, %{
      title: unique_ballot_title(),
      questions: questions
    })
  end

  @doc """
  Creates a `Flick.Ballots.Ballot` entity in the `Flick.Repo` for the passed in
  optional attributes.

  When not provided, all required attributes will be generated.
  """
  def ballot_fixture(attrs \\ %{}) do
    attrs = valid_ballot_attributes(attrs)
    {:ok, ballot} = Flick.Ballots.create_ballot(attrs)
    ballot
  end
end
