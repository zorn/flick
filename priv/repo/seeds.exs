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
  Flick.Ballots.create_ballot(%{
    "questions" => %{
      "0" => %{
        "_persistent_id" => "0",
        "title" => "What is your sandwich preference?",
        "possible_answers" => "Turkey, Ham, Roast Beef"
      },
      "1" => %{
        "_persistent_id" => "1",
        "title" => "What is your snack preference?",
        "possible_answers" => "Chips, Fruit, Candy"
      },
      "2" => %{
        "_persistent_id" => "2",
        "title" => "What is your drink preference?",
        "possible_answers" => "Soda, Water, Juice"
      }
    },
    "questions_drop" => [""],
    "questions_sort" => ["0", "1", "2"],
    "title" => "Lunch Survey"
  })

dbg(ballot)

sandwich_question = Enum.at(ballot.questions, 0)
snack_question = Enum.at(ballot.questions, 1)
drink_question = Enum.at(ballot.questions, 2)

{:ok, vote} =
  Flick.Votes.record_vote(%{
    "ballot_id" => ballot.id,
    "answers" => [
      %{
        "question_id" => sandwich_question.id,
        "ranked_answers" => ["Turkey", "Roast Beef", "Ham"]
      },
      %{
        "question_id" => snack_question.id,
        "ranked_answers" => ["Chips", "Fruit", "Candy"]
      },
      %{
        "question_id" => drink_question.id,
        "ranked_answers" => ["Soda", "Juice", "Water"]
      }
    ]
  })
