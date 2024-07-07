defmodule Flick.VotesTest do
  use Flick.DataCase, async: true

  alias Flick.Votes
  alias Flick.Votes.Vote
  alias Flick.Votes.RankedAnswer
  alias Flick.Ballots

  describe "record_vote/2" do
    setup do
      ballot =
        ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: "Pizza, Tacos, Sushi, Burgers"
        )

      {:ok, ballot} = Ballots.publish_ballot(ballot)

      {:ok, published_ballot: ballot}
    end

    test "success: creates a vote recording the passed in answers", %{
      published_ballot: published_ballot
    } do
      published_ballot_id = published_ballot.id

      assert {:ok, vote} =
               Votes.record_vote(published_ballot, %{
                 "ranked_answers" => [
                   %{"value" => "Tacos"},
                   %{"value" => "Pizza"},
                   %{"value" => "Burgers"},
                   %{"value" => "Sushi"}
                 ]
               })

      assert %Vote{
               ballot_id: ^published_ballot_id,
               ranked_answers: [
                 %RankedAnswer{value: "Tacos"},
                 %RankedAnswer{value: "Pizza"},
                 %RankedAnswer{value: "Burgers"},
                 %RankedAnswer{value: "Sushi"}
               ]
             } = vote
    end

    test "success: a vote does not need to rank every possible answer", %{
      published_ballot: published_ballot
    } do
      published_ballot_id = published_ballot.id

      assert {:ok, vote} =
               Votes.record_vote(published_ballot, %{
                 "ranked_answers" => [
                   %{"value" => "Sushi"},
                   %{"value" => "Pizza"}
                 ]
               })

      assert %Vote{
               ballot_id: ^published_ballot_id,
               ranked_answers: [
                 %RankedAnswer{value: "Sushi"},
                 %RankedAnswer{value: "Pizza"}
               ]
             } = vote
    end

    test "failure: a vote should not include an answer value that is not present in the ballot",
         %{
           published_ballot: published_ballot
         } do
      attrs = %{
        "ranked_answers" => [
          %{"value" => "Forbidden Hot Dogs"},
          %{"value" => "Illegal Cookies"}
        ]
      }

      assert {:error, changeset} = Votes.record_vote(published_ballot, attrs)

      assert "invalid answers: Forbidden Hot Dogs, Illegal Cookies" in errors_on(changeset).ranked_answers
    end
  end
end
