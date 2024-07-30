defmodule FlickWeb.Ballots.EditorLiveTest do
  @moduledoc """
  Verifies the expected logic of the ballot editor live view.
  """

  use FlickWeb.ConnCase, async: true

  describe "When used as the view for `/create-ballot`" do
    setup ~M{conn} do
      {:ok, view, _html} = live(conn, ~p"/create-ballot")

      ~M{conn, view}
    end

    test "success: renders a create ballot form", ~M{view} do
      assert has_element?(view, "h2", "Create Ballot")
      assert has_element?(view, "#ballot_question_title")
      assert has_element?(view, "#ballot_possible_answers")
      assert has_element?(view, "#ballot_url_slug")
    end

    test "success: submitting valid form creates ballot and redirects", ~M{view} do
      response =
        view
        |> form("form",
          ballot: %{
            question_title: "What's your favorite color?",
            possible_answers: "Red, Green, Blue",
            url_slug: "favorite-color"
          }
        )
        |> render_submit()

      # TODO: Add assertions about this somewhere.
      assert {:error, {:redirect, %{to: _somewhere}}} =
               response
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

  describe "When used as the view for `/<url-slug>/<secret>/edit`" do
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
