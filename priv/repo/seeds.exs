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
    possible_answers: "Turkey, Ham, Roast Beef"
  })

{:ok, _vote} =
  Flick.RankedVoting.record_vote(ballot, %{
    "ranked_answers" => [
      %{"value" => "Turkey"},
      %{"value" => "Roast Beef"},
      %{"value" => "Ham"}
    ]
  })
