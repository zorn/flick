defmodule Flick.VotesTest do
  use Flick.DataCase, async: true

  alias Flick.Votes
  alias Flick.Votes.Vote
  alias Flick.Votes.Answer
  alias Flick.Ballots

  describe "record_vote/2" do
    setup do
      ballot =
        ballot_fixture(
          title: "Mike's Dinner Poll",
          questions: [
            %{
              title: "What's for dinner?",
              possible_answers: "Pizza, Tacos, Sushi, Burgers"
            }
          ]
        )

      {:ok, ballot} = Ballots.publish_ballot(ballot)

      {:ok, published_ballot: ballot}
    end

    test "success: creates a vote recording the passed in answers", %{
      published_ballot: published_ballot
    } do
      published_ballot_id = published_ballot.id
      question_id = hd(published_ballot.questions).id

      assert {:ok, vote} =
               Votes.record_vote(published_ballot, %{
                 "answers" => [
                   %{
                     "question_id" => question_id,
                     "ranked_answers" => ["Tacos", "Pizza", "Burgers", "Sushi"]
                   }
                 ]
               })

      assert %Vote{
               ballot_id: ^published_ballot_id,
               answers: [
                 %Answer{
                   question_id: ^question_id,
                   ranked_answers: ["Tacos", "Pizza", "Burgers", "Sushi"]
                 }
               ]
             } = vote
    end

    test "success: a vote does not need to rank every possible answer", %{
      published_ballot: published_ballot
    } do
      published_ballot_id = published_ballot.id
      question_id = hd(published_ballot.questions).id

      assert {:ok, vote} =
               Votes.record_vote(published_ballot, %{
                 "answers" => [
                   %{
                     "question_id" => question_id,
                     "ranked_answers" => ["Burgers", "Sushi"]
                   }
                 ]
               })

      assert %Vote{
               ballot_id: ^published_ballot_id,
               answers: [
                 %Answer{
                   question_id: ^question_id,
                   ranked_answers: ["Burgers", "Sushi"]
                 }
               ]
             } = vote
    end

    test "failure: a vote must answer all ballot questions", %{
      published_ballot: published_ballot
    } do
      assert {:error, changeset} =
               Votes.record_vote(published_ballot, %{
                 "answers" => []
               })

      assert "can't be blank" in errors_on(changeset).answers
    end

    test "failure: a vote can only have a single answer per ballot question", %{
      published_ballot: published_ballot
    } do
      assert {:error, changeset} =
               Votes.record_vote(published_ballot, %{
                 "answers" => [
                   %{
                     "question_id" => hd(published_ballot.questions).id,
                     "ranked_answers" => ["Pizza", "Tacos", "Sushi", "Burgers"]
                   },
                   %{
                     "question_id" => hd(published_ballot.questions).id,
                     "ranked_answers" => ["Burgers", "Sushi", "Tacos", "Pizza"]
                   }
                 ]
               })

      assert "should not include duplicate question ids" in errors_on(changeset).answers
    end

    test "failure: a vote should not include an answer value that is not present in the ballot",
         %{
           published_ballot: published_ballot
         } do
      attrs = %{
        "answers" => [
          %{
            "question_id" => hd(published_ballot.questions).id,
            "ranked_answers" => ["Forbidden Hot Dogs", "Illegal Cookies"]
          }
        ]
      }

      assert {:error, changeset} = Votes.record_vote(published_ballot, attrs)

      assert "invalid answers: Forbidden Hot Dogs, Illegal Cookies" in errors_on(changeset).answers
    end
  end
end
