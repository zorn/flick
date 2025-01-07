defmodule FlickWeb.Vote.VoteCaptureLiveTest do
  @moduledoc """
  Verifies the expected logic of `FlickWeb.Vote.ResultsLive`.

  Vote: http://localhost:4000/ballot/<url-slug>/results
  """

  use FlickWeb.ConnCase, async: true

  alias Flick.RankedVoting.Ballot

  setup ~M{conn} do
    ballot =
      ballot_fixture(%{
        question_title: "What movie should we go see?",
        possible_answers: "WarGames, The Matrix, Tron",
        url_slug: "movie-night"
      })

    {:ok, ballot} = Flick.RankedVoting.publish_ballot(ballot)
    populate_ballot_with_votes(ballot)

    {:ok, ballot} = Flick.RankedVoting.close_ballot(ballot)
    {:ok, view, _html} = live(conn, ~p"/ballot/movie-night/results")
    ~M{conn, view, ballot}
  end

  test "renders results of a ballot", ~M{view, ballot} do
    assert render(view) =~
             "For the ballot asking <strong>#{ballot.question_title}</strong> the results in!"

    assert render(view) =~ "With a total of 25 votes cast"
  end

  test "redirects any unpublished ballots", ~M{conn} do
    unpublished_ballot = ballot_fixture()

    assert {:error, {:redirect, %{to: "/", flash: flash}}} =
             live(conn, ~p"/ballot/#{unpublished_ballot.url_slug}/results")

    assert flash["error"] == "This ballot is not closed and results are unavailable."
  end

  test "redirects any non-closed ballots", ~M{conn} do
    {:ok, published_ballot} = Flick.RankedVoting.publish_ballot(ballot_fixture())

    assert {:error, {:redirect, %{to: "/", flash: flash}}} =
             live(conn, ~p"/ballot/#{published_ballot.url_slug}/results")

    assert flash["error"] == "This ballot is not closed and results are unavailable."
  end

  defp populate_ballot_with_votes(%Ballot{published_at: published_at} = ballot)
       when not is_nil(published_at) do
    # This assumes a ballot with three possible answers.
    for _ <- 1..25 do
      available_answers = Ballot.possible_answers_as_list(ballot.possible_answers)

      if length(available_answers) != 3 do
        raise """
          The ballot with the question title '#{ballot.question_title}' must have at least three possible answers. We saw '#{available_answers}'.
        """
      end

      first_answer = Enum.random(available_answers)
      available_answers = Enum.reject(available_answers, &(&1 == first_answer))
      second_answer = Enum.random(available_answers)
      available_answers = Enum.reject(available_answers, &(&1 == second_answer))
      third_answer = Enum.random(available_answers)

      # For a little variance, we'll sometime use an empty quote value for the third
      # answer, since a user need not always provide a full ranked list answer.
      third_answer = Enum.random([third_answer, ""])

      full_name = if Enum.random(1..5) > 1, do: Faker.Person.name()

      {:ok, _vote} =
        Flick.RankedVoting.create_vote(ballot, %{
          "full_name" => full_name,
          "ranked_answers" => [
            %{"value" => first_answer},
            %{"value" => second_answer},
            %{"value" => third_answer}
          ]
        })
    end
  end
end
