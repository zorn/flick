defmodule FlickWeb.Vote.VoteCaptureLiveTest do
  @moduledoc """
  Verifies the expected logic of `FlickWeb.Vote.VoteCaptureLive`.

  Vote: http://localhost:4000/<url-slug>
  """

  use FlickWeb.ConnCase, async: true

  alias Flick.RankedVoting.Ballot

  setup ~M{conn} do
    prepublished_ballot =
      ballot_fixture(%{
        question_title: "What movie should we go see?",
        possible_answers: "Hackers, Sneakers, WarGames, The Matrix, Tron",
        url_slug: "movie-night"
      })

    {:ok, ballot} = Flick.RankedVoting.publish_ballot(prepublished_ballot)

    {:ok, view, _html} = live(conn, ~p"/ballot/movie-night")
    ~M{conn, view, ballot}
  end

  test "success: renders a vote form", ~M{view, ballot} do
    # Presents the question.
    assert has_element?(view, "#question-title", ballot.question_title)

    # Presents the possible ranked answer as select inputs.
    assert has_element?(view, ranked_answer_selector(0))
    assert has_element?(view, ranked_answer_selector(1))
    assert has_element?(view, ranked_answer_selector(2))
    assert has_element?(view, ranked_answer_selector(3))
    assert has_element?(view, ranked_answer_selector(4))

    # Validate the select input has all the possible answers.
    Enum.each(Ballot.possible_answers_as_list(ballot.possible_answers), fn answer ->
      assert has_element?(
               view,
               "#{ranked_answer_selector(0)} option[value=\"#{answer}\"]",
               answer
             )
    end)
  end

  test "success: can submit a form and create a vote", ~M{view} do
    payload = %{
      "ranked_answers" => %{
        "0" => %{"_persistent_id" => "0", "value" => "The Matrix"},
        "1" => %{"_persistent_id" => "1", "value" => "Tron"},
        "2" => %{"_persistent_id" => "2", "value" => "Sneakers"},
        "3" => %{"_persistent_id" => "3", "value" => "WarGames"},
        "4" => %{"_persistent_id" => "4", "value" => "Hackers"}
      }
    }

    view
    |> form("form", vote: payload)
    |> render_submit()

    # Assert upon submit the page redirects, and the vote was created.
    flash = assert_redirected(view, ~p"/")
    assert flash["info"] == "Vote recorded."

    # FIXME: Test the vote was created. Will require the creation of a
    # `list_votes_for_ballot/1` function.
  end

  test "redirects when ballot is an unpublished draft", ~M{conn} do
    ballot_fixture(%{url_slug: "red-car"})
    assert {:error, {:redirect, %{to: "/", flash: flash}}} = live(conn, ~p"/ballot/red-car")
    assert flash["error"] == "This ballot is unpublished and can not accept votes."
  end

  defp ranked_answer_selector(index) do
    "div[data-feedback-for=\"vote[ranked_answers][#{index}][value]\"]"
  end
end
