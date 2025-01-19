defmodule Support.Fixtures.BallotFixture do
  @moduledoc """
  Provides functions to allows tests to easily create and stage
  `Flick.RankedVoting.Ballot` entities for testing.
  """

  alias Flick.RankedVoting.Ballot

  @doc """
  Returns a map of valid attributes for a `Flick.RankedVoting.Ballot` entity,
  allowing for the passed in attributes to override defaults.
  """
  @spec valid_ballot_attributes(map()) :: map()
  def valid_ballot_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      question_title: "What day should have dinner?",
      possible_answers: "Monday, Tuesday, Wednesday, Thursday, Friday",
      url_slug: "dinner-day-#{System.unique_integer()}"
    })
  end

  @doc """
  Creates a `Flick.RankedVoting.Ballot` entity in the `Flick.Repo` for the passed in
  optional attributes.

  When not provided, all required attributes will be generated.
  """
  @spec ballot_fixture(map()) :: Ballot.t()
  def ballot_fixture(attrs \\ %{}) do
    attrs = valid_ballot_attributes(attrs)
    {:ok, ballot} = Flick.RankedVoting.create_ballot(attrs)
    ballot
  end

  @doc """
  Creates a `Flick.RankedVoting.Ballot` entity in the `Flick.Repo` for the passed in
  optional attributes and then publishes the ballot.

  When not provided, all required attributes will be generated.
  """
  @spec published_ballot_fixture(map()) :: Ballot.t()
  def published_ballot_fixture(attrs \\ %{}, published_at \\ nil) do
    published_at = published_at || DateTime.utc_now()

    attrs = valid_ballot_attributes(attrs)
    {:ok, ballot} = Flick.RankedVoting.create_ballot(attrs)
    {:ok, published_ballot} = Flick.RankedVoting.publish_ballot(ballot, published_at)
    published_ballot
  end

  @doc """
  Creates a `Flick.RankedVoting.Ballot` entity in the `Flick.Repo` for the passed in
  optional attributes, publishes the ballot, and then closes the ballot.

  When not provided, all required attributes will be generated.
  """
  @spec closed_ballot_fixture(map()) :: Ballot.t()
  def closed_ballot_fixture(attrs \\ %{}, closed_at \\ nil) do
    closed_at = closed_at || DateTime.utc_now()
    attrs = valid_ballot_attributes(attrs)
    {:ok, ballot} = Flick.RankedVoting.create_ballot(attrs)
    {:ok, published_ballot} = Flick.RankedVoting.publish_ballot(ballot)
    {:ok, closed_ballot} = Flick.RankedVoting.close_ballot(published_ballot, closed_at)
    closed_ballot
  end
end
