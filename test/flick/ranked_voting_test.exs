defmodule Flick.RankedVotingTest do
  @moduledoc """
  Validates logic of the `Flick.RankedVoting` module.
  """

  use Flick.DataCase, async: true

  alias Flick.RankedVoting
  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.RankedAnswer
  alias Flick.RankedVoting.Vote
  alias Support.Fixtures.BallotFixture

  @empty_values ["", nil, " "]

  describe "create_ballot/1" do
    test "success: creates a unpublished ballot that is retrievable from the repo" do
      {:ok, %Ballot{id: id}} =
        RankedVoting.create_ballot(%{
          question_title: "What is your favorite color?",
          possible_answers: "Red, Green, Blue",
          url_slug: "favorite-color"
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
          "possible_answers" => "Pizza, Tacos, Sushi",
          "url_slug" => "favorite-food"
        })

      assert %Ballot{
               question_title: "What is your favorite food?",
               possible_answers: "Pizza, Tacos, Sushi",
               published_at: nil
             } = RankedVoting.get_ballot!(id)
    end

    test "success: `question_title` can be more than 255 characters" do
      long_question_title = String.duplicate("a", 1_000)

      valid_ballot_attrs =
        BallotFixture.valid_ballot_attributes()
        |> Map.put(:question_title, long_question_title)

      assert {:ok, ballot} = RankedVoting.create_ballot(valid_ballot_attrs)
      assert long_question_title == ballot.question_title
    end

    test "failure: `question_title` is required" do
      for empty_value <- @empty_values do
        assert {:error, changeset} = RankedVoting.create_ballot(%{question_title: empty_value})
        assert "can't be blank" in errors_on(changeset).question_title
      end
    end

    test "failure: `possible_answers` is required" do
      for empty_value <- @empty_values do
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

    test "failure: `url_slug` is required" do
      for empty_value <- @empty_values do
        assert {:error, changeset} = RankedVoting.create_ballot(%{url_slug: empty_value})
        assert "can't be blank" in errors_on(changeset).url_slug
      end
    end

    test "failure: `url_slug` must be unique" do
      ballot_fixture(url_slug: "popular-slug")

      assert {:error, changeset} =
               RankedVoting.create_ballot(%{
                 question_title: "What is your favorite color?",
                 possible_answers: "Red, Green, Blue",
                 url_slug: "popular-slug"
               })

      assert "has already been taken" in errors_on(changeset).url_slug
    end

    test "failure: `url_slug` can only contain alphanumeric or hyphens" do
      for bad_value <- [
            "nobangs!",
            "noquestionmarks?",
            "no spaces",
            "no backslashes\\",
            "no forwardslashes/"
          ] do
        assert {:error, changeset} = RankedVoting.create_ballot(%{url_slug: bad_value})
        assert "can only contain letters, numbers, and hyphens" in errors_on(changeset).url_slug
      end
    end

    test "failure: `url_slug` can not be less than than 3 characters" do
      for bad_value <- ["1", "22"] do
        assert {:error, changeset} = RankedVoting.create_ballot(%{url_slug: bad_value})
        assert "should be at least 3 character(s)" in errors_on(changeset).url_slug
      end
    end

    test "failure: `url_slug` can not be more than 255 characters" do
      too_long_value = String.duplicate("a", 256)
      assert {:error, changeset} = RankedVoting.create_ballot(%{url_slug: too_long_value})
      assert "should be at most 255 character(s)" in errors_on(changeset).url_slug
    end

    test "failure: can not attempt to create a ballot that is already `published`" do
      assert {:error, changeset} =
               RankedVoting.create_ballot(%{published_at: ~U[2021-01-01 00:00:00Z]})

      assert "new ballots can not be published" in errors_on(changeset).published_at
    end

    test "success: `secret` is created after row insertion" do
      %Ballot{secret: secret} = ballot_fixture()
      assert uuid_string?(secret)
    end

    test "success: `description` can be more than 255 characters" do
      long_description = String.duplicate("a", 1_000)

      valid_ballot_attrs =
        BallotFixture.valid_ballot_attributes()
        |> Map.put(:description, long_description)

      assert {:ok, ballot} = RankedVoting.create_ballot(valid_ballot_attrs)
      assert long_description == ballot.description
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

      for empty_value <- @empty_values do
        changes = %{"question_title" => empty_value}
        assert {:error, changeset} = RankedVoting.update_ballot(ballot, changes)
        assert "can't be blank" in errors_on(changeset).question_title
      end
    end

    test "failure: can not update a published ballot" do
      ballot = published_ballot_fixture()

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
      ballot = ballot_fixture()
      published_at = DateTime.utc_now()
      assert {:ok, published_ballot} = RankedVoting.publish_ballot(ballot, published_at)
      assert {:error, :ballot_already_published} = RankedVoting.publish_ballot(published_ballot)
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

  describe "create_vote/2" do
    setup do
      prepublished_ballot =
        ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: "Pizza, Tacos, Sushi, Burgers"
        )

      {:ok, ballot} = RankedVoting.publish_ballot(prepublished_ballot)

      {:ok, published_ballot: ballot}
    end

    test "success: creates a vote recording the passed in answers", ~M{published_ballot} do
      published_ballot_id = published_ballot.id

      assert {:ok, vote} =
               RankedVoting.create_vote(published_ballot, %{
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
               RankedVoting.create_vote(published_ballot, %{
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

    test "success: a vote can contain an optional `full_name` value", ~M{published_ballot} do
      published_ballot_id = published_ballot.id

      assert {:ok, %Vote{ballot_id: ^published_ballot_id, full_name: "John Doe"}} =
               RankedVoting.create_vote(published_ballot, %{
                 "ranked_answers" => [%{"value" => "Sushi"}],
                 "full_name" => "John Doe"
               })
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

      assert {:error, changeset} = RankedVoting.create_vote(published_ballot, attrs)

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

      assert {:error, changeset} = RankedVoting.create_vote(published_ballot, attrs)
      %Ecto.Changeset{changes: %{ranked_answers: ranked_answers_changesets}} = changeset
      pizza_1 = Enum.at(ranked_answers_changesets, 0)
      tacos = Enum.at(ranked_answers_changesets, 1)
      pizza_2 = Enum.at(ranked_answers_changesets, 2)

      assert "duplicates are not allowed" in errors_on(pizza_1).value
      assert %{} == errors_on(tacos)
      assert "duplicates are not allowed" in errors_on(pizza_2).value
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

      assert {:error, changeset} = RankedVoting.create_vote(published_ballot, attrs)
      %Ecto.Changeset{changes: %{ranked_answers: ranked_answers_changesets}} = changeset
      first_ranked_answer = Enum.at(ranked_answers_changesets, 0)
      assert "can't be blank" in errors_on(first_ranked_answer).value
    end

    test "failure: a vote can not be created for an unpublished ballot" do
      unpublished_ballot = ballot_fixture()
      assert {:error, changeset} = RankedVoting.create_vote(unpublished_ballot, %{})
      assert "ballot must be published" in errors_on(changeset).ballot_id
    end
  end

  describe "update_vote/2" do
    setup do
      ballot =
        ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: "Pizza, Tacos, Sushi, Burgers"
        )

      {:ok, published_ballot} = RankedVoting.publish_ballot(ballot)

      {:ok, vote} =
        RankedVoting.create_vote(published_ballot, %{
          "ranked_answers" => [
            %{"value" => "Tacos"},
            %{"value" => "Pizza"},
            %{"value" => "Burgers"},
            %{"value" => "Sushi"}
          ]
        })

      {:ok, ballot: ballot, vote: vote}
    end

    test "success: can update the weight of a previously created vote",
         ~M{ballot, vote} do
      assert {:ok, %Vote{weight: 2.1}} = RankedVoting.update_vote(ballot, vote, %{weight: 2.1})
    end

    test "success: can not update the ranked answers", ~M{ballot, vote} do
      assert {:ok, ^vote} = RankedVoting.update_vote(ballot, vote, %{"ranked_answers" => []})
    end

    test "success: can not update the associated ballot", ~M{ballot, vote} do
      change = %{"ballot_id" => Ecto.UUID.generate()}
      assert {:ok, ^vote} = RankedVoting.update_vote(ballot, vote, change)
    end
  end

  describe "change_vote/2" do
    setup do
      ballot =
        published_ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: "Pizza, Tacos, Sushi, Burgers"
        )

      {:ok, vote} =
        RankedVoting.create_vote(ballot, %{
          "ranked_answers" => [
            %{"value" => "Tacos"},
            %{"value" => "Pizza"},
            %{"value" => "Burgers"}
          ]
        })

      {:ok, published_ballot: ballot, vote: vote}
    end

    test "generates a valid changeset for a previously created vote", ~M{vote} do
      assert %Ecto.Changeset{valid?: true} = RankedVoting.change_vote(vote, %{})
    end

    test "generates a valid changeset when the `weight` change is an empty string", ~M{vote} do
      # This is because "Empty values are always replaced by the default value
      # of the respective field."
      # https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4-options
      changeset = RankedVoting.change_vote(vote, %{weight: ""})
      assert %Ecto.Changeset{valid?: true} = changeset
    end

    test "generates an invalid changeset for a previously created vote", ~M{vote} do
      changeset = RankedVoting.change_vote(vote, %{weight: "-1.0"})
      assert %Ecto.Changeset{valid?: false} = changeset
      assert "must be greater than or equal to 0.0" in errors_on(changeset).weight
    end
  end

  describe "get_ballot_results_report/1" do
    setup do
      ballot =
        published_ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: "Pizza, Tacos, Sushi, Burgers"
        )

      {:ok, ballot: ballot}
    end

    test "returns expected vote report", ~M{ballot} do
      {:ok, _vote} =
        RankedVoting.create_vote(ballot, %{
          "ranked_answers" => [
            # 5 points
            %{"value" => "Burgers"},
            # 4 points
            %{"value" => "Pizza"},
            # 3 points
            %{"value" => "Tacos"},
            # 2 points
            %{"value" => "Sushi"}
          ]
        })

      assert [
               %{points: 5.0, value: "Burgers"},
               %{points: 4.0, value: "Pizza"},
               %{points: 3.0, value: "Tacos"},
               %{points: 2.0, value: "Sushi"}
             ] =
               RankedVoting.get_ballot_results_report(ballot.id)
    end

    test "returns expected vote report when a custom weight is used", ~M{ballot} do
      # Create a vote, it will have a weight of 1.
      {:ok, _vote} =
        RankedVoting.create_vote(ballot, %{
          "ranked_answers" => [
            # 5 points
            %{"value" => "Tacos"},
            # 4 points
            %{"value" => "Pizza"},
            # 3 points
            %{"value" => "Burgers"}
          ]
        })

      # Create a second vote and give it a weight of 2.
      {:ok, vote} =
        RankedVoting.create_vote(ballot, %{
          "ranked_answers" => [
            # 10 points
            %{"value" => "Sushi"},
            # 8 points
            %{"value" => "Burgers"},
            # 6 points
            %{"value" => "Pizza"},
            # 4 points
            %{"value" => "Tacos"}
          ]
        })

      {:ok, _vote} = RankedVoting.update_vote(ballot, vote, %{weight: 2})

      assert [
               %{points: 11.0, value: "Burgers"},
               %{points: 10.0, value: "Pizza"},
               %{points: 10.0, value: "Sushi"},
               %{points: 9.0, value: "Tacos"}
             ] =
               RankedVoting.get_ballot_results_report(ballot.id)
    end
  end

  defp uuid_string?(value) when byte_size(value) > 16 do
    # More info on why the byte_size check is necessary:
    # https://fosstodon.org/@tylerayoung/112872657415154548
    case Ecto.UUID.cast(value) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp uuid_string?(_), do: false
end
