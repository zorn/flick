defmodule Flick.RankedVotingTest do
  @moduledoc """
  Validates logic of the `Flick.RankedVoting` module.
  """

  use Flick.DataCase, async: true

  alias Flick.RankedVoting
  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting.PossibleAnswer
  alias Flick.RankedVoting.RankedAnswer
  alias Flick.RankedVoting.Vote
  alias Support.Fixtures.BallotFixture

  @empty_values ["", nil, " "]

  describe "create_ballot/1" do
    test "success: creates a unpublished ballot that is retrievable from the repo" do
      {:ok, %Ballot{id: id}} =
        RankedVoting.create_ballot(%{
          question_title: "What is your favorite color?",
          possible_answers: [%{value: "Red"}, %{value: "Green"}, %{value: "Blue"}],
          url_slug: "favorite-color"
        })

      assert %Ballot{
               question_title: "What is your favorite color?",
               possible_answers: [
                 %PossibleAnswer{value: "Red"},
                 %PossibleAnswer{value: "Green"},
                 %PossibleAnswer{value: "Blue"}
               ],
               published_at: nil
             } =
               RankedVoting.get_ballot!(id)
    end

    test "success: can create a ballot with web payload format (string keys)" do
      {:ok, %Ballot{id: id}} =
        RankedVoting.create_ballot(%{
          "question_title" => "What is your favorite food?",
          "possible_answers" => %{
            "0" => %{"value" => "Pizza"},
            "1" => %{"value" => "Tacos"},
            "2" => %{"value" => "Sushi"}
          },
          "url_slug" => "favorite-food"
        })

      assert %Ballot{
               question_title: "What is your favorite food?",
               possible_answers: [
                 %PossibleAnswer{value: "Pizza"},
                 %PossibleAnswer{value: "Tacos"},
                 %PossibleAnswer{value: "Sushi"}
               ],
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
      assert {:error, changeset} = RankedVoting.create_ballot(%{question_title: "Q"})
      assert "must have at least two answers" in errors_on(changeset).possible_answers
    end

    test "failure: `possible_answers` must include at least two answers" do
      assert {:error, changeset} =
               RankedVoting.create_ballot(%{possible_answers: [%{value: "one"}]})

      assert "must have at least two answers" in errors_on(changeset).possible_answers
    end

    test "success: a ballot may have 100 possible answers" do
      answers = for n <- 1..100, do: "Answer #{n}"
      attrs = BallotFixture.valid_ballot_attributes(%{possible_answers: answers})

      assert {:ok, ballot} = RankedVoting.create_ballot(attrs)
      assert Ballot.possible_answer_values(ballot) == answers
    end

    test "failure: a ballot can't have more than 100 possible answers" do
      answers = for n <- 1..101, do: "Answer #{n}"
      attrs = BallotFixture.valid_ballot_attributes(%{possible_answers: answers})

      assert {:error, changeset} = RankedVoting.create_ballot(attrs)
      assert "must have at most 100 answer(s)" in errors_on(changeset).possible_answers
    end

    test "failure: a blank possible answer is rejected" do
      for empty_value <- @empty_values do
        attrs = BallotFixture.valid_ballot_attributes(%{possible_answers: ["Red", "Blue"]})
        attrs = %{attrs | possible_answers: [%{value: "Red"}, %{value: empty_value}]}

        assert {:error, changeset} = RankedVoting.create_ballot(attrs)
        assert [%{}, %{value: ["can't be blank"]}] = errors_on(changeset).possible_answers
      end
    end

    test "success: a possible answer may be 500 characters after trimming" do
      longest = String.duplicate("a", 500)
      attrs = BallotFixture.valid_ballot_attributes(%{possible_answers: ["  #{longest}  ", "b"]})

      assert {:ok, ballot} = RankedVoting.create_ballot(attrs)
      assert Ballot.possible_answer_values(ballot) == [longest, "b"]
    end

    test "failure: a possible answer over 500 characters is rejected on its row" do
      too_long = String.duplicate("a", 501)
      attrs = BallotFixture.valid_ballot_attributes(%{possible_answers: ["Red", too_long]})

      assert {:error, changeset} = RankedVoting.create_ballot(attrs)

      assert [%{}, %{value: ["should be at most 500 character(s)"]}] =
               errors_on(changeset).possible_answers
    end

    test "failure: a possible answer containing a newline is rejected on its row" do
      for newline <- ["\n", "\r\n"] do
        attrs =
          BallotFixture.valid_ballot_attributes(%{
            possible_answers: ["Red", "Blue#{newline}Green"]
          })

        assert {:error, changeset} = RankedVoting.create_ballot(attrs)

        assert [%{}, %{value: ["can't contain line breaks"]}] =
                 errors_on(changeset).possible_answers
      end
    end

    test "failure: a repeated possible answer is rejected on the repeating row, ignoring case and spacing" do
      attrs =
        BallotFixture.valid_ballot_attributes(%{possible_answers: ["Dune", "Emma", " dune "]})

      assert {:error, changeset} = RankedVoting.create_ballot(attrs)

      assert [%{}, %{}, %{value: ["repeats an earlier answer"]}] =
               errors_on(changeset).possible_answers
    end

    test "success: `possible_answers` are trimmed and may contain commas" do
      attrs =
        BallotFixture.valid_ballot_attributes(%{
          possible_answers: ["  Project Hail Mary ", "Tomorrow, and Tomorrow, and Tomorrow"]
        })

      assert {:ok, ballot} = RankedVoting.create_ballot(attrs)

      assert Ballot.possible_answer_values(ballot) == [
               "Project Hail Mary",
               "Tomorrow, and Tomorrow, and Tomorrow"
             ]
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
                 possible_answers: [%{value: "Red"}, %{value: "Green"}],
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
      assert_raise ArgumentError,
                   "`published_at` can not be set during creation or mutation of a ballot",
                   fn ->
                     RankedVoting.create_ballot(%{published_at: ~U[2021-01-01 00:00:00Z]})
                   end
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
      ballot =
        ballot_fixture(%{question_title: "some-title", possible_answers: ["a", "b", "c", "d"]})

      ballot_id = ballot.id

      existing_answers =
        ballot.possible_answers
        |> Enum.with_index()
        |> Map.new(fn {answer, index} ->
          {"#{index}", %{"id" => answer.id, "value" => answer.value}}
        end)

      changes = %{
        "question_title" => "some-title-changed",
        "possible_answers" => Map.put(existing_answers, "4", %{"value" => "e"})
      }

      assert {:ok,
              %Ballot{
                id: ^ballot_id,
                question_title: "some-title-changed",
                published_at: nil
              } = updated_ballot} = RankedVoting.update_ballot(ballot, changes)

      assert Ballot.possible_answer_values(updated_ballot) == ["a", "b", "c", "d", "e"]

      assert Enum.take(Enum.map(updated_ballot.possible_answers, & &1.id), 4) ==
               Enum.map(ballot.possible_answers, & &1.id)
    end

    test "success: removes a dropped answer and keeps the rest" do
      ballot = ballot_fixture(%{possible_answers: ["a", "b", "c"]})
      [a, b, c] = ballot.possible_answers

      changes = %{
        "possible_answers" => %{
          "0" => %{"id" => a.id, "value" => "a"},
          "1" => %{"id" => b.id, "value" => "b"},
          "2" => %{"id" => c.id, "value" => "c"}
        },
        "possible_answers_drop" => ["1"]
      }

      assert {:ok, updated_ballot} = RankedVoting.update_ballot(ballot, changes)
      assert Ballot.possible_answer_values(updated_ballot) == ["a", "c"]
      assert Enum.map(updated_ballot.possible_answers, & &1.id) == [a.id, c.id]
    end

    test "success: a legacy ballot with a repeated answer can change fields other than its answers" do
      ballot = ballot_fixture(%{possible_answers: ["Pizza", "Tacos"]})

      {:ok, ballot} =
        ballot
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_embed(:possible_answers, [
          %PossibleAnswer{value: "Pizza"},
          %PossibleAnswer{value: "Pizza"}
        ])
        |> Repo.update()

      assert {:ok, updated_ballot} =
               RankedVoting.update_ballot(ballot, %{"question_title" => "New title"})

      assert updated_ballot.question_title == "New title"
    end

    test "failure: adding an answer that repeats an existing one is rejected" do
      ballot = ballot_fixture(%{possible_answers: ["Pizza", "Tacos"]})
      [pizza, tacos] = ballot.possible_answers

      changes = %{
        "possible_answers" => %{
          "0" => %{"id" => pizza.id, "value" => "Pizza"},
          "1" => %{"id" => tacos.id, "value" => "Tacos"},
          "2" => %{"value" => "PIZZA"}
        }
      }

      assert {:error, changeset} = RankedVoting.update_ballot(ballot, changes)

      assert [%{}, %{}, %{value: ["repeats an earlier answer"]}] =
               errors_on(changeset).possible_answers
    end

    test "success: an answer dropped in the same change doesn't count as a repeat" do
      ballot = ballot_fixture(%{possible_answers: ["Pizza", "Tacos"]})
      [pizza, tacos] = ballot.possible_answers

      changes = %{
        "possible_answers" => %{
          "0" => %{"id" => pizza.id, "value" => "Pizza"},
          "1" => %{"id" => tacos.id, "value" => "Tacos"},
          "2" => %{"value" => "pizza"}
        },
        "possible_answers_drop" => ["0"]
      }

      assert {:ok, updated_ballot} = RankedVoting.update_ballot(ballot, changes)
      assert Ballot.possible_answer_values(updated_ballot) == ["Tacos", "pizza"]
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

      assert {:error, :can_only_update_draft_ballot} =
               RankedVoting.update_ballot(ballot, %{title: "some new title"})
    end

    test "failure: can not update a closed ballot" do
      ballot = closed_ballot_fixture()

      assert {:error, :can_only_update_draft_ballot} =
               RankedVoting.update_ballot(ballot, %{title: "some new title"})
    end
  end

  describe "publish_ballot/2" do
    test "success: you can publish a non-published ballot" do
      ballot = ballot_fixture()
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

  describe "close_ballot/2" do
    test "success: closes a published ballot" do
      ballot = published_ballot_fixture()
      closed_at = DateTime.utc_now()
      assert {:ok, closed_ballot} = RankedVoting.close_ballot(ballot, closed_at)
      assert %Ballot{closed_at: ^closed_at} = closed_ballot
    end

    test "failure: can not close an unpublished ballot" do
      ballot = ballot_fixture()
      assert {:error, :ballot_not_published} = RankedVoting.close_ballot(ballot)
    end

    test "failure: can not close a closed ballot" do
      ballot = closed_ballot_fixture()
      assert {:error, :ballot_already_closed} = RankedVoting.close_ballot(ballot)
    end
  end

  describe "ballot_status/1" do
    test "returns `:draft` for a non-published ballot" do
      ballot = ballot_fixture()
      assert :draft = RankedVoting.ballot_status(ballot)
    end

    test "returns `:published` for a published ballot" do
      ballot = published_ballot_fixture()
      assert :published = RankedVoting.ballot_status(ballot)
    end

    test "returns `:closed` for a closed ballot" do
      ballot = closed_ballot_fixture()
      assert :closed = RankedVoting.ballot_status(ballot)
    end

    # VacuousTest can't see the RankedVoting call, because the test makes it through apply/3.
    # credo:disable-for-next-line Jump.CredoChecks.VacuousTest
    test "raises when encountering an unknown status" do
      ballot = %Ballot{published_at: nil, closed_at: DateTime.utc_now()}

      assert_raise RuntimeError, "invalid state observed", fn ->
        # apply/3 is used instead of a direct call to suppress the Elixir type
        # checker warning — we're intentionally passing an impossible struct state
        # to test the defensive raise branch.
        # credo:disable-for-next-line Credo.Check.Refactor.Apply
        apply(RankedVoting, :ballot_status, [ballot])
      end
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

  describe "Ballot.possible_answer_values/1" do
    test "success: returns the possible answer values in order" do
      ballot = ballot_fixture(%{possible_answers: ["Red", "Green", "Blue"]})

      assert Ballot.possible_answer_values(ballot) == ["Red", "Green", "Blue"]
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

    test "failure: a sort param far beyond the answer cap builds no more than one extra answer" do
      ballot = ballot_fixture()
      change = %{"possible_answers_sort" => List.duplicate("new", 100_000)}

      changeset = RankedVoting.change_ballot(ballot, change)

      assert length(Ecto.Changeset.get_field(changeset, :possible_answers)) == 101

      # `errors_on/1` reports the blank rows' errors under this key. Read the cap
      # error from the ballot changeset instead.
      assert {"must have at most %{count} answer(s)", [count: 100]} =
               changeset.errors[:possible_answers]
    end

    test "failure: an answers map far beyond the answer cap builds no more than one extra answer" do
      ballot = ballot_fixture()
      answers = for index <- 0..99_999, into: %{}, do: {"#{index}", %{"value" => ""}}

      changeset = RankedVoting.change_ballot(ballot, %{"possible_answers" => answers})

      assert length(Ecto.Changeset.get_field(changeset, :possible_answers)) == 101

      assert {"must have at most %{count} answer(s)", [count: 100]} =
               changeset.errors[:possible_answers]
    end

    test "failure: an answers list far beyond the answer cap builds no more than one extra answer" do
      ballot = ballot_fixture()
      answers = List.duplicate(%{"value" => ""}, 100_000)

      changeset = RankedVoting.change_ballot(ballot, %{"possible_answers" => answers})

      assert length(Ecto.Changeset.get_field(changeset, :possible_answers)) == 101

      assert {"must have at most %{count} answer(s)", [count: 100]} =
               changeset.errors[:possible_answers]
    end
  end

  describe "create_vote/2" do
    setup do
      prepublished_ballot =
        ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: ["Pizza", "Tacos", "Sushi", "Burgers"]
        )

      {:ok, ballot} = RankedVoting.publish_ballot(prepublished_ballot)

      {:ok, published_ballot: ballot}
    end

    test "success: accepts an answer that contains a comma" do
      ballot =
        published_ballot_fixture(%{
          possible_answers: ["Tomorrow, and Tomorrow, and Tomorrow", "Dune"]
        })

      assert {:ok, %Vote{ranked_answers: [%RankedAnswer{value: value} | _]}} =
               RankedVoting.create_vote(ballot, %{
                 "ranked_answers" => [%{"value" => "Tomorrow, and Tomorrow, and Tomorrow"}]
               })

      assert value == "Tomorrow, and Tomorrow, and Tomorrow"
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

    test "failure: a vote can't rank more answers than the ballot allows", ~M{published_ballot} do
      attrs = %{
        "ranked_answers" => [
          %{"value" => "Pizza"},
          %{"value" => "Tacos"},
          %{"value" => "Sushi"},
          %{"value" => "Burgers"},
          %{"value" => ""}
        ]
      }

      assert {:error, changeset} = RankedVoting.create_vote(published_ballot, attrs)

      assert {"must have at most %{count} answer(s)", [count: 4]} =
               changeset.errors[:ranked_answers]
    end

    test "failure: ranked answers far beyond the rank limit build no more than one extra answer",
         ~M{published_ballot} do
      oversized_list = List.duplicate(%{"value" => ""}, 100_000)
      oversized_map = for index <- 0..99_999, into: %{}, do: {"#{index}", %{"value" => ""}}

      for ranked_answers <- [oversized_list, oversized_map] do
        attrs = %{"ranked_answers" => ranked_answers}

        assert {:error, changeset} = RankedVoting.create_vote(published_ballot, attrs)
        assert length(Ecto.Changeset.get_field(changeset, :ranked_answers)) == 6

        assert {"must have at most %{count} answer(s)", [count: 4]} =
                 changeset.errors[:ranked_answers]
      end
    end

    test "failure: a single invalid answer carries a count of one for pluralization",
         %{published_ballot: published_ballot} do
      attrs = %{"ranked_answers" => [%{"value" => "Forbidden Hot Dogs"}]}

      assert {:error, changeset} = RankedVoting.create_vote(published_ballot, attrs)

      assert {"invalid answer(s): %{answers}", [count: 1, answers: "Forbidden Hot Dogs"]} =
               changeset.errors[:ranked_answers]
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

      assert "invalid answer(s): Forbidden Hot Dogs, Illegal Cookies" in errors_on(changeset).ranked_answers
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
          possible_answers: ["Pizza", "Tacos", "Sushi", "Burgers"]
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
          possible_answers: ["Pizza", "Tacos", "Sushi", "Burgers"]
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

  describe "list_votes_for_ballot_id/1" do
    setup do
      ballot =
        published_ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: ["Pizza", "Tacos", "Sushi", "Burgers"]
        )

      {:ok, published_ballot: ballot}
    end

    test "returns a lists votes of a ballot", ~M{published_ballot} do
      assert [] = RankedVoting.list_votes_for_ballot_id(published_ballot.id)

      {:ok, vote} =
        RankedVoting.create_vote(published_ballot, %{
          "ranked_answers" => [
            %{"value" => "Tacos"},
            %{"value" => "Pizza"},
            %{"value" => "Burgers"}
          ]
        })

      assert [^vote] = RankedVoting.list_votes_for_ballot_id(published_ballot.id)
    end
  end

  describe "count_votes_for_ballot_id/1" do
    setup do
      ballot =
        published_ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: ["Pizza", "Tacos", "Sushi", "Burgers"]
        )

      {:ok, published_ballot: ballot}
    end

    test "returns a count of the votes of a ballot", ~M{published_ballot} do
      assert 0 = RankedVoting.count_votes_for_ballot_id(published_ballot.id)

      {:ok, _vote} =
        RankedVoting.create_vote(published_ballot, %{
          "ranked_answers" => [
            %{"value" => "Tacos"},
            %{"value" => "Pizza"},
            %{"value" => "Burgers"}
          ]
        })

      assert 1 = RankedVoting.count_votes_for_ballot_id(published_ballot.id)
    end
  end

  describe "get_ballot_results_report/1" do
    setup do
      ballot =
        published_ballot_fixture(
          question_title: "What's for dinner?",
          possible_answers: ["Pizza", "Tacos", "Sushi", "Burgers"]
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
