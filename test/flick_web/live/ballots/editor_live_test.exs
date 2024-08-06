defmodule FlickWeb.Ballots.EditorLiveTest do
  @moduledoc """
  Verifies the expected logic of `FlickWeb.Ballots.EditorLive`.

  Create URL: http://localhost:4000/create-ballot
  Edit URL: http://localhost:4000/<url-slug>/<secret>/edit
  """

  use FlickWeb.ConnCase, async: true

  alias Flick.RankedVoting.Ballot
  alias Flick.RankedVoting

  describe "When used for creation, eg: `/create-ballot`" do
    setup ~M{conn} do
      {:ok, view, _html} = live(conn, ~p"/create-ballot")
      ~M{conn, view}
    end

    test "success: renders a create ballot form", ~M{view} do
      assert has_element?(view, "h2", "Create a Ballot")
      assert has_element?(view, "#ballot_question_title")
      assert has_element?(view, "#ballot_possible_answers")
      assert has_element?(view, "#ballot_url_slug")
    end

    test "success: submitting valid form creates ballot and redirects", ~M{view} do
      payload = %{
        question_title: "What's your favorite color?",
        possible_answers: "Red, Green, Blue",
        url_slug: "favorite-color"
      }

      response =
        view
        |> form("form", ballot: payload)
        |> render_submit()

      # Assert upon submit the page redirects, and the ballot was created.
      assert {:error, {:redirect, %{to: redirect_target}}} = response
      assert "/favorite-color/" <> secret = redirect_target
      assert %Ballot{url_slug: "favorite-color"} = RankedVoting.get_ballot!(secret)
    end

    test "failure: `question_title` is required", ~M{view} do
      render_form_submit(view, %{question_title: ""})
      assert has_element?(view, feedback_selector("question_title"), "can't be blank")
    end

    test "failure: `possible_answers` is required", ~M{view} do
      render_form_submit(view, %{possible_answers: ""})
      assert has_element?(view, feedback_selector("possible_answers"), "can't be blank")
    end

    test "failure: `url_slug` is required", ~M{view} do
      render_form_submit(view, %{url_slug: ""})
      assert has_element?(view, feedback_selector("url_slug"), "can't be blank")
    end
  end

  describe "When used for editing, eg: `/<url-slug>/<secret>/edit`" do
    setup ~M{conn} do
      ballot = ballot_fixture()
      {:ok, view, _html} = live(conn, ~p"/#{ballot.url_slug}/#{ballot.id}/edit")
      ~M{conn, view, ballot}
    end

    test "success: renders an edit ballot form", ~M{view} do
      assert has_element?(view, "h2", "Edit Ballot")
      assert has_element?(view, "#ballot_question_title")
      assert has_element?(view, "#ballot_possible_answers")
      assert has_element?(view, "#ballot_url_slug")
    end

    test "success: submitting valid form creates ballot and redirects", ~M{view, ballot} do
      expected_id = ballot.id

      payload = %{
        question_title: "new-title",
        possible_answers: "purple, pink, yellow",
        url_slug: "new-url-slug"
      }

      response =
        view
        |> form("form", ballot: payload)
        |> render_submit()

      # Assert upon submit the page redirects, and the ballot was edited, and
      # maintains it's identity.
      assert {:error, {:redirect, %{to: redirect_target}}} = response
      assert "/new-url-slug/" <> secret = redirect_target

      assert %Ballot{
               id: ^expected_id,
               question_title: "new-title",
               possible_answers: "purple, pink, yellow",
               url_slug: "new-url-slug"
             } = RankedVoting.get_ballot!(secret)
    end
  end

  defp render_form_submit(view, payload) do
    view
    |> form("form", ballot: payload)
    |> render_submit()
  end

  defp feedback_selector(field) do
    "div[phx-feedback-for=\"ballot[#{field}]\"]"
  end
end
