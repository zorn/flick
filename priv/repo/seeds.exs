# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Flick.Repo.insert!(%Flick.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

defmodule SeedScripts do
  alias Flick.RankedVoting.Ballot

  @doc """
  Given a published `Flick.RankedVoting.Ballot` will populate said ballot with 25 votes.

  It is expected that the ballot has three possible answers.
  """
  def populate_ballot_with_votes(%Ballot{published_at: published_at} = ballot)
      when not is_nil(published_at) do
    # This assumes a ballot with three possible answers.

    for _ <- 1..25 do
      available_answers = Ballot.possible_answers_as_list(ballot.possible_answers)

      if length(available_answers) != 3 do
        raise """
          The ballot with the question title '#{ballot.question_title}' must have at least three possible answers. We saw '#{available_answers}'.
        """
      end

      first_answer = Enum.random(available_answers)
      available_answers = Enum.reject(available_answers, &(&1 == first_answer))
      second_answer = Enum.random(available_answers)
      available_answers = Enum.reject(available_answers, &(&1 == second_answer))
      third_answer = Enum.random(available_answers)

      # For a little variance, we'll sometime use an empty quote value for the third
      # answer, since a user need not always provide a full ranked list answer.
      third_answer = Enum.random([third_answer, ""])

      full_name = if Enum.random(1..5) > 1, do: Faker.Person.name()

      {:ok, _vote} =
        Flick.RankedVoting.create_vote(ballot, %{
          "full_name" => full_name,
          "ranked_answers" => [
            %{"value" => first_answer},
            %{"value" => second_answer},
            %{"value" => third_answer}
          ]
        })
    end
  end
end

# Create a published ballot with some votes.
{:ok, sandwich_ballot} =
  Flick.RankedVoting.create_ballot(%{
    question_title: "What is your sandwich preference?",
    possible_answers: "Turkey, Ham, Roast Beef",
    url_slug: "sandwich-preference"
  })

{:ok, sandwich_ballot_published} = Flick.RankedVoting.publish_ballot(sandwich_ballot)
SeedScripts.populate_ballot_with_votes(sandwich_ballot_published)

# Create a draft ballot.
{:ok, _color_ballot} =
  Flick.RankedVoting.create_ballot(%{
    question_title: "What is your favorite color?",
    possible_answers: "Red, Green, Blue",
    url_slug: "favorite-color"
  })

# Create a closed ballot.
{:ok, fruit_ballot} =
  Flick.RankedVoting.create_ballot(%{
    question_title: "What is your favorite fruit?",
    possible_answers: "Apple, Banana, Orange",
    url_slug: "favorite-fruit"
  })

{:ok, fruit_ballot_published} = Flick.RankedVoting.publish_ballot(fruit_ballot)
SeedScripts.populate_ballot_with_votes(fruit_ballot_published)
{:ok, _fruit_ballot_closed} = Flick.RankedVoting.close_ballot(fruit_ballot_published)
