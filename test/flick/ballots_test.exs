defmodule Flick.BallotsTest do
  use Flick.DataCase

  alias Flick.Ballots
  alias Flick.Ballots.Ballot
  alias Flick.Ballots.Question

  describe "create_ballot/1" do
    test "success: creates a ballot with questions" do
      title = "My first ballot"
      question_1 = %Question{title: "What is your favorite color?"}
      question_2 = %Question{title: "What is your favorite food?"}
      questions = [question_1, question_2]

      {:ok, ballot} = Ballots.create_ballot(title, questions)

      assert %Ballot{
               title: ^title,
               questions: [
                 %Question{title: "What is your favorite color?"},
                 %Question{title: "What is your favorite food?"}
               ]
             } = ballot
    end
  end

  test "failure: title is required" do
    empty_values = ["", nil, " "]

    for empty_value <- empty_values do
      assert {:error, changeset} = Ballots.create_ballot(empty_value, [])
      assert "can't be blank" in errors_on(changeset).title
    end
  end

  test "failure: at least one question is required" do
    assert {:error, changeset} = Ballots.create_ballot("My first ballot", [])
    assert "can't be blank" in errors_on(changeset).questions
  end

  describe "list_ballots/1" do
    test "success: lists ballots" do
      ballot_a = ballot_fixture()
      ballot_b = ballot_fixture()

      assert ballots = Ballots.list_ballots()

      assert length(ballots) == 2
      assert Enum.find(ballots, &match?(^ballot_a, &1))
      assert Enum.find(ballots, &match?(^ballot_b, &1))
    end
  end
end
