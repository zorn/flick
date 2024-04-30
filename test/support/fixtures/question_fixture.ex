defmodule Support.Fixtures.QuestionFixture do
  @moduledoc """
  Provides functions to allows tests to easily create
  `Flick.Ballots.Question` for testing.
  """

  @doc """
  Generates a unique question title.
  """
  def unique_question_title, do: "some-question-#{System.unique_integer()}"

  @doc """
  Returns a map of valid attributes for a `Flick.Ballots.Question` entity,
  allowing for the passed in attributes to override defaults.
  """
  def valid_question_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{title: unique_question_title()})
  end

  @doc """
  Creates a `Flick.Ballots.Question` value for the passed in optional attributes.

  When not provided, all required attributes will be generated.
  """
  def question_fixture(attrs \\ %{}) do
    %{title: title} = valid_question_attributes(attrs)
    %Flick.Ballots.Question{title: title}
  end
end
