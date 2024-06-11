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
               Votes.record_vote(%{
                 "ballot_id" => published_ballot_id,
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
               Votes.record_vote(%{
                 "ballot_id" => published_ballot_id,
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
      published_ballot_id = published_ballot.id

      assert {:error, _changeset} =
               Votes.record_vote(%{
                 "ballot_id" => published_ballot_id,
                 "answers" => []
               })
    end

    # test "failure: a vote can only have a single answer per ballot question" do
    # end

    # test "failure: a answer must align to a know answer option of the ballot" do
    # end
  end
end
