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

{:ok, _} =
  Flick.Ballots.create_ballot(%{
    "questions" => %{
      "0" => %{"_persistent_id" => "0", "title" => "What is your sandwich preference?"},
      "1" => %{"_persistent_id" => "1", "title" => "What is your snack preference?"},
      "2" => %{"_persistent_id" => "2", "title" => "What is your drink preference?"}
    },
    "questions_drop" => [""],
    "questions_sort" => ["0", "1", "2"],
    "title" => "Lunch Survey"
  })
