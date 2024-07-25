defmodule Flick.RankedVotingTest do
  @moduledoc """
  Validates logic of the `Flick.RankedVoting` module.
  """

  use Flick.DataCase, async: true

  alias Flick.RankedVoting
  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.Vote
  alias Flick.RankedVoting.RankedAnswer

  describe "create_ballot/1" do
    test "success: creates a unpublished ballot that is retrievable from the repo" do
      {:ok, %Ballot{id: id}} =
        RankedVoting.create_ballot(%{
          question_title: "What is your favorite color?",
          possible_answers: "Red, Green, Blue"
        })

      assert %Ballot{
               question_title: "What is your favorite color?",
               possible_answers: "Red, Green, Blue",
               published_at: nil
             } =
               RankedVoting.get_ballot!(id)
    end

    test "success: can create a ballot with web payload format (string keys)" do
      {:ok, %Ballot{id: id}} =
        RankedVoting.create_ballot(%{
          "question_title" => "What is your favorite food?",
          "possible_answers" => "Pizza, Tacos, Sushi"
        })

      assert %Ballot{
               question_title: "What is your favorite food?",
               possible_answers: "Pizza, Tacos, Sushi",
               published_at: nil
             } = RankedVoting.get_ballot!(id)
    end

    test "failure: `question_title` is required" do
      empty_values = ["", nil, " "]

      for empty_value <- empty_values do
        assert {:error, changeset} = RankedVoting.create_ballot(%{question_title: empty_value})
        assert "can't be blank" in errors_on(changeset).question_title
      end
    end

    test "failure: `possible_answers` is required" do
      empty_values = ["", nil, " "]

      for empty_value <- empty_values do
        assert {:error, changeset} = RankedVoting.create_ballot(%{possible_answers: empty_value})
        assert "can't be blank" in errors_on(changeset).possible_answers
      end
    end

    test "failure: `possible_answers` must not include empty answers" do
      assert {:error, changeset} = RankedVoting.create_ballot(%{possible_answers: "one,,two"})
      assert "can't contain empty answers" in errors_on(changeset).possible_answers
    end

    test "failure: `possible_answers` must not include new lines" do
      assert {:error, changeset} = RankedVoting.create_ballot(%{possible_answers: "one,\ntwo"})
      assert "can't contain new lines" in errors_on(changeset).possible_answers
    end

    test "failure: `possible_answers` must include at least two answers" do
      assert {:error, changeset} = RankedVoting.create_ballot(%{possible_answers: "one"})
      assert "must contain at least two answers" in errors_on(changeset).possible_answers
    end
  end

  describe "update_ballot/1" do
    test "success: updates a ballot title and questions" do
      ballot = ballot_fixture(%{question_title: "some-title", possible_answers: "a, b, c, d"})
      ballot_id = ballot.id

      changes = %{
        "question_title" => "some-title-changed",
        "possible_answers" => "a, b, c, d, e"
      }

      assert {:ok,
              %Ballot{
                id: ^ballot_id,
                question_title: "some-title-changed",
                possible_answers: "a, b, c, d, e",
                published_at: nil
              }} = RankedVoting.update_ballot(ballot, changes)
    end

    test "failure: `question_title` is required" do
      ballot = ballot_fixture()
      empty_values = ["", nil, " "]

      for empty_value <- empty_values do
        changes = %{"question_title" => empty_value}
        assert {:error, changeset} = RankedVoting.update_ballot(ballot, changes)
        assert "can't be blank" in errors_on(changeset).question_title
      end
    end

    test "failure: can not update a published ballot" do
      ballot = ballot_fixture(%{published_at: DateTime.utc_now()})

      assert {:error, :can_not_update_published_ballot} =
               RankedVoting.update_ballot(ballot, %{title: "some new title"})
    end
  end

  describe "publish_ballot/2" do
    test "success: you can publish a non-published ballot" do
      ballot = ballot_fixture(%{published_at: nil})
      published_at = DateTime.utc_now()
      assert {:ok, published_ballot} = RankedVoting.publish_ballot(ballot, published_at)
      assert %Ballot{published_at: ^published_at} = published_ballot
    end

    test "failure: you can not publish a published ballot" do
      ballot = ballot_fixture(%{published_at: DateTime.utc_now()})
      assert {:error, :ballot_already_published} = RankedVoting.publish_ballot(ballot)
    end
  end

  describe "list_ballots/1" do
    test "success: lists ballots start with zero ballots" do
      assert [] = RankedVoting.list_ballots()
    end

    test "success: lists ballots" do
      ballot_a = ballot_fixture()
      ballot_b = ballot_fixture()

      assert ballots = RankedVoting.list_ballots()

      assert length(ballots) == 2
      assert Enum.find(ballots, &match?(^ballot_a, &1))
      assert Enum.find(ballots, &match?(^ballot_b, &1))
    end
  end

  describe "get_ballot!/1" do
    test "success: returns a ballot" do
      %Ballot{id: id, question_title: question_title} = ballot_fixture()
      assert %Ballot{id: ^id, question_title: ^question_title} = RankedVoting.get_ballot!(id)
    end

    test "failure: raises when the ballot does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        RankedVoting.get_ballot!(Ecto.UUID.generate())
      end
    end
  end

  describe "fetch_ballot/1" do
    test "success: returns a ballot" do
      %Ballot{id: id, question_title: question_title} = ballot_fixture()

      assert {:ok, %Ballot{id: ^id, question_title: ^question_title}} =
               RankedVoting.fetch_ballot(id)
    end

    test "failure: returns `:not_found` when the ballot does not exist" do
      assert {:error, :ballot_not_found} = RankedVoting.fetch_ballot(Ecto.UUID.generate())
    end
  end

  describe "change_ballot/2" do
    test "success: returns a changeset" do
      ballot = ballot_fixture(%{question_title: "some-question-title"})
      change = %{"question_title" => "some-question-title-changed"}

      assert %Ecto.Changeset{
               changes: %{question_title: "some-question-title-changed"},
               valid?: true
             } = RankedVoting.change_ballot(ballot, change)
    end
  end

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
               RankedVoting.record_vote(published_ballot, %{
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
               RankedVoting.record_vote(published_ballot, %{
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

      assert {:error, changeset} = RankedVoting.record_vote(published_ballot, attrs)

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

      assert {:error, changeset} = RankedVoting.record_vote(published_ballot, attrs)
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

      assert {:error, changeset} = RankedVoting.record_vote(published_ballot, attrs)
      %Ecto.Changeset{changes: %{ranked_answers: ranked_answers_changesets}} = changeset
      first_ranked_answer = Enum.at(ranked_answers_changesets, 0)
      assert "first answer is required" in errors_on(first_ranked_answer).value
    end
  end

  describe "change_vote/2" do
    # TODO
  end
end
