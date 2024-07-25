defmodule Flick.VotesTest do
  use Flick.DataCase, async: true

  alias Flick.Votes
  alias Flick.Votes.Vote
  alias Flick.Votes.RankedAnswer
  alias Flick.RankedVoting

  describe "record_vote/2" do
    setup do
      ballot =
        ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: "Pizza, Tacos, Sushi, Burgers"
        )

      {:ok, ballot} = RankedVoting.publish_ballot(ballot)

      {:ok, published_ballot: ballot}
    end

    test "success: creates a vote recording the passed in answers", ~M{published_ballot} do
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

    test "success: a vote does not need to rank every possible answer", ~M{published_ballot} do
      published_ballot_id = published_ballot.id

      assert {:ok, vote} =
               Votes.record_vote(published_ballot, %{
                 "ranked_answers" => [
                   %{"value" => "Sushi"},
                   %{"value" => "Pizza"},
                   %{"value" => ""},
                   %{"value" => ""}
                 ]
               })

      assert %Vote{
               ballot_id: ^published_ballot_id,
               ranked_answers: [
                 %RankedAnswer{value: "Sushi"},
                 %RankedAnswer{value: "Pizza"},
                 %RankedAnswer{value: nil},
                 %RankedAnswer{value: nil}
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

    test "failure: a vote should not include duplicate answer values",
         %{
           published_ballot: published_ballot
         } do
      attrs = %{
        "ranked_answers" => [
          %{"value" => "Pizza"},
          %{"value" => "Tacos"},
          %{"value" => "Pizza"}
        ]
      }

      assert {:error, changeset} = Votes.record_vote(published_ballot, attrs)
      %Ecto.Changeset{changes: %{ranked_answers: ranked_answers_changesets}} = changeset
      pizza_1 = Enum.at(ranked_answers_changesets, 0)
      tacos = Enum.at(ranked_answers_changesets, 1)
      pizza_2 = Enum.at(ranked_answers_changesets, 2)

      assert "answers must not be duplicated" in errors_on(pizza_1).value
      assert %{} == errors_on(tacos)
      assert "answers must not be duplicated" in errors_on(pizza_2).value
    end

    test "failure: a vote needs to include at least one ranked answer", ~M{published_ballot} do
      attrs = %{
        "ranked_answers" => [
          %{"value" => ""},
          %{"value" => ""},
          %{"value" => ""},
          %{"value" => ""}
        ]
      }

      assert {:error, changeset} = Votes.record_vote(published_ballot, attrs)
      %Ecto.Changeset{changes: %{ranked_answers: ranked_answers_changesets}} = changeset
      first_ranked_answer = Enum.at(ranked_answers_changesets, 0)
      assert "first answer is required" in errors_on(first_ranked_answer).value
    end
  end

  describe "change_vote/2" do
    # TODO
  end
end
