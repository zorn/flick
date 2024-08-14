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

{:ok, ballot} =
  Flick.RankedVoting.create_ballot(%{
    question_title: "What is your sandwich preference?",
    possible_answers: "Turkey, Ham, Roast Beef",
    url_slug: "sandwich-preference"
  })

{:ok, published_ballot} = Flick.RankedVoting.publish_ballot(ballot)

for _ <- 1..25 do
  available_answers = ["Turkey", "Ham", "Roast Beef"]

  first_answer = Enum.random(available_answers)
  available_answers = Enum.reject(available_answers, &(&1 == first_answer))
  second_answer = Enum.random(available_answers)
  available_answers = Enum.reject(available_answers, &(&1 == second_answer))
  third_answer = Enum.random(available_answers)

  # For a little variance, we'll sometime use an empty quote value for the third
  # answer, since a user need not always provide a full ranked list answer.
  third_answer = Enum.random([third_answer, ""])

  {:ok, _vote} =
    Flick.RankedVoting.create_vote(published_ballot, %{
      "ranked_answers" => [
        %{"value" => first_answer},
        %{"value" => second_answer},
        %{"value" => third_answer}
      ]
    })
end
