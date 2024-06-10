defmodule Flick.VotesTest do
  use Flick.DataCase, async: true

  alias Flick.Votes
  alias Flick.Votes.Vote

  describe "record_vote/2" do
    setup do
      question =
        question_fixture(%{
          title: "What's for dinner?",
          answer_options: [
            %{title: "Pizza"},
            %{title: "Tacos"},
            %{title: "Sushi"},
            %{title: "Burgers"}
          ]
        })
        |> Map.from_struct()
        |> dbg()

      ballot = ballot_fixture(title: "Mike's Dinner Poll", questions: [question])

      {:ok, ballot: ballot}
    end

    test "success: creates a vote recording the passed in answers", %{ballot: ballot} do
      dbg(ballot)
      assert false
    end

    # test "failure: a vote must answer all ballot questions" do
    # end

    # test "failure: a vote can only have a single answer per ballot question" do
    # end

    # test "failure: a answer must align to a know answer option of the ballot" do
    # end
  end
end
