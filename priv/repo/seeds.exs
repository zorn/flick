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

alias Flick.Ballots
alias Flick.Ballots.Question

{:ok, _} =
  Ballots.create_ballot("Lunch Survey", [
    %Question{title: "What is your sandwich preference?"},
    %Question{title: "What is your snack preference?"},
    %Question{title: "What is your drink preference?"}
  ])
