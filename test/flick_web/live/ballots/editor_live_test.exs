defmodule FlickWeb.Ballots.EditorLiveTest do
  @moduledoc """
  Verifies the expected logic of `FlickWeb.Ballots.EditorLive`.

  Create URL: http://localhost:4000/create-ballot
  Edit URL: http://localhost:4000/<url-slug>/<secret>/edit
  """

  use FlickWeb.ConnCase, async: true

  alias Flick.RankedVoting
  alias Flick.RankedVoting.Ballot

  describe "When used for creation, eg: `/ballot/new`" do
    setup ~M{conn} do
      {:ok, view, _html} = live(conn, ~p"/ballot/new")
      ~M{conn, view}
    end

    test "success: renders a create ballot form", ~M{view} do
      assert has_element?(view, "h2", "Create a Ballot")
      assert has_element?(view, "#ballot_question_title")
      assert has_element?(view, "#ballot_url_slug")
    end

    test "success: starts with two empty answer rows", ~M{view} do
      assert has_element?(view, "#ballot_possible_answers_0_value")
      assert has_element?(view, "#ballot_possible_answers_1_value")
      refute has_element?(view, "#ballot_possible_answers_2_value")
    end

    test "success: adding an answer adds a row", ~M{view} do
      assert has_element?(
               view,
               "#add-possible-answer[name='ballot[possible_answers_sort][]'][value=new]"
             )

      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers_sort: ["0", "1", "new"]}})

      assert has_element?(view, "#ballot_possible_answers_2_value")
    end

    test "success: removing an answer removes its row", ~M{view} do
      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers_sort: ["0", "1", "new"]}})

      assert has_element?(
               view,
               "#remove-possible-answer-2[name='ballot[possible_answers_drop][]'][value='2']"
             )

      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers_drop: ["2"]}})

      refute has_element?(view, "#ballot_possible_answers_2_value")
    end

    test "success: remove is disabled when only two answers remain", ~M{view} do
      assert has_element?(view, "#remove-possible-answer-0[disabled]")
      assert has_element?(view, "#remove-possible-answer-1[disabled]")

      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers_sort: ["0", "1", "new"]}})

      refute has_element?(view, "#remove-possible-answer-0[disabled]")
    end

    test "success: submitting valid form creates ballot and redirects", ~M{view} do
      payload = %{
        question_title: "What's your favorite color?",
        possible_answers: %{
          "0" => %{value: "Red"},
          "1" => %{value: "Green, or Teal"}
        },
        url_slug: "favorite-color"
      }

      response =
        view
        |> form("form", ballot: payload)
        |> render_submit()

      # Assert upon submit the page redirects, and the ballot was created.
      assert {:error, {:redirect, %{to: redirect_target}}} = response
      assert "/ballot/favorite-color/" <> secret = redirect_target
      ballot = RankedVoting.get_ballot_by_url_slug_and_secret!("favorite-color", secret)
      assert Ballot.answer_values(ballot) == ["Red", "Green, or Teal"]
    end

    test "failure: `question_title` is required", ~M{view} do
      render_form_submit(view, %{question_title: ""})
      assert has_element?(view, feedback_selector("question_title"), "can't be blank")
    end

    test "failure: fewer than two answers shows an error", ~M{view} do
      render_form_submit(view, %{possible_answers: %{"0" => %{value: "Red"}, "1" => %{value: ""}}})

      assert has_element?(view, "#possible-answers-errors", "must have at least two answers")
    end

    test "failure: `url_slug` is required", ~M{view} do
      render_form_submit(view, %{url_slug: ""})
      assert has_element?(view, feedback_selector("url_slug"), "can't be blank")
    end
  end

  describe "When used for editing, eg: `/ballot/<url-slug>/<secret>/edit`" do
    setup ~M{conn} do
      ballot = ballot_fixture()
      {:ok, view, _html} = live(conn, ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}/edit")
      ~M{conn, view, ballot}
    end

    test "success: renders an edit ballot form", ~M{view} do
      assert has_element?(view, "h2", "Edit Ballot")
      assert has_element?(view, "#ballot_question_title")
      assert has_element?(view, "#ballot_url_slug")
    end

    test "success: loads the ballot's answers into rows in order", ~M{view} do
      assert has_element?(view, "#ballot_possible_answers_0_value[value=Monday]")
      assert has_element?(view, "#ballot_possible_answers_4_value[value=Friday]")
      refute has_element?(view, "#ballot_possible_answers_5_value")
    end

    test "success: submitting valid form creates ballot and redirects", ~M{view, ballot} do
      expected_id = ballot.id

      payload = %{
        question_title: "new-title",
        possible_answers: %{
          "0" => %{value: "purple"},
          "1" => %{value: "pink"},
          "2" => %{value: "yellow"},
          "3" => %{value: ""},
          "4" => %{value: ""}
        },
        url_slug: "new-url-slug"
      }

      response =
        view
        |> form("form", ballot: payload)
        |> render_submit()

      # Assert upon submit the page redirects, and the ballot was edited, and
      # maintains it's identity.
      assert {:error, {:redirect, %{to: redirect_target}}} = response
      assert "/ballot/new-url-slug/" <> secret = redirect_target

      assert %Ballot{
               id: ^expected_id,
               question_title: "new-title",
               url_slug: "new-url-slug"
             } = ballot = RankedVoting.get_ballot_by_url_slug_and_secret!("new-url-slug", secret)

      assert Ballot.answer_values(ballot) == ["purple", "pink", "yellow"]
    end
  end

  defp render_form_submit(view, payload) do
    view
    |> form("form", ballot: payload)
    |> render_submit()
  end

  defp feedback_selector(field) do
    "div[data-feedback-for=\"ballot[#{field}]\"]"
  end
end
