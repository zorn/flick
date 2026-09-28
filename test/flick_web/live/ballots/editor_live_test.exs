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

      view
      |> form("#ballot-form")
      |> render_change(%{
        ballot: %{
          possible_answers: %{
            "0" => %{value: "Red"},
            "1" => %{value: "Green"},
            "2" => %{value: "Blue"}
          }
        }
      })

      assert has_element?(
               view,
               "#remove-possible-answer-1[name='ballot[possible_answers_drop][]'][value='1']"
             )

      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers_drop: ["1"]}})

      # Each row keeps its DOM id, so the rows are checked by their input names.
      assert has_element?(view, "input[name='ballot[possible_answers][0][value]'][value=Red]")
      assert has_element?(view, "input[name='ballot[possible_answers][1][value]'][value=Blue]")
      refute has_element?(view, "input[name='ballot[possible_answers][2][value]']")
      refute has_element?(view, "#possible-answers input[value=Green]")
    end

    test "success: swapping two blank rows still changes the render", ~M{view} do
      # The hook fixes positions and focus only when the list re-renders. Each
      # row's persistent id moves with it, so even blank rows trade input ids.
      assert has_element?(
               view,
               "input[name='ballot[possible_answers][0][value]']#ballot_possible_answers_0_value"
             )

      reorder(view, ["1", "0"])

      assert has_element?(
               view,
               "input[name='ballot[possible_answers][0][value]']#ballot_possible_answers_1_value"
             )

      assert has_element?(
               view,
               "input[name='ballot[possible_answers][1][value]']#ballot_possible_answers_0_value"
             )
    end

    test "success: remove is disabled when only two answers remain", ~M{view} do
      assert has_element?(view, "#remove-possible-answer-0[disabled]")
      assert has_element?(view, "#remove-possible-answer-1[disabled]")

      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers_sort: ["0", "1", "new"]}})

      refute has_element?(view, "#remove-possible-answer-0[disabled]")
    end

    test "success: add is disabled with a note at 100 answers", ~M{view} do
      refute has_element?(view, "#add-possible-answer[disabled]")
      refute has_element?(view, "#possible-answers-max-note")

      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers_sort: List.duplicate("new", 100)}})

      assert has_element?(view, "#ballot_possible_answers_99_value")
      assert has_element?(view, "#add-possible-answer[disabled]")
      assert has_element?(view, "#possible-answers-max-note", "100")
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
      assert Ballot.possible_answer_values(ballot) == ["Red", "Green, or Teal"]
    end

    test "success: saving drops answer rows left blank", ~M{view} do
      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers_sort: ["0", "1", "new"]}})

      payload = %{
        question_title: "What's your favorite color?",
        possible_answers: %{
          "0" => %{value: "Red"},
          "1" => %{value: "  "},
          "2" => %{value: "Blue"}
        },
        url_slug: "favorite-color-blank-rows"
      }

      assert {:error, {:redirect, %{to: "/ballot/favorite-color-blank-rows/" <> secret}}} =
               render_form_submit(view, payload)

      ballot =
        RankedVoting.get_ballot_by_url_slug_and_secret!("favorite-color-blank-rows", secret)

      assert Ballot.possible_answer_values(ballot) == ["Red", "Blue"]
    end

    test "failure: saving a non-string answer value shows an error", ~M{view} do
      # The form never sends a list here, but a crafted request can. The
      # `form/3` helper refuses fields the page lacks, so the test sends the
      # event directly.
      render_submit(view, "save", %{
        "ballot" => %{
          "question_title" => "What's your favorite color?",
          "possible_answers" => %{
            "0" => %{"value" => ["Red"]},
            "1" => %{"value" => "Blue"}
          },
          "url_slug" => "favorite-color-malformed"
        }
      })

      assert has_element?(view, answer_feedback_selector(0), "is invalid")
    end

    test "failure: `question_title` is required", ~M{view} do
      render_form_submit(view, %{question_title: ""})
      assert has_element?(view, feedback_selector("question_title"), "can't be blank")
    end

    test "failure: fewer than two answers shows an error below the add button", ~M{view} do
      render_form_submit(view, %{possible_answers: %{"0" => %{value: "Red"}, "1" => %{value: ""}}})

      assert has_element?(
               view,
               "#add-possible-answer ~ #possible-answers-errors",
               "must have at least two answers"
             )
    end

    test "failure: a failed save keeps the minimum number of answer rows", ~M{view} do
      render_form_submit(view, %{possible_answers: %{"0" => %{value: ""}, "1" => %{value: ""}}})

      assert has_element?(view, "#possible-answers-errors", "must have at least two answers")
      assert has_element?(view, "input[name='ballot[possible_answers][0][value]']")
      assert has_element?(view, "input[name='ballot[possible_answers][1][value]']")
    end

    test "failure: a failed save keeps filled answers and pads to the minimum", ~M{view} do
      render_form_submit(view, %{possible_answers: %{"0" => %{value: "Red"}, "1" => %{value: ""}}})

      assert has_element?(view, "input[name='ballot[possible_answers][0][value]'][value=Red]")
      assert has_element?(view, "input[name='ballot[possible_answers][1][value]']")
      refute has_element?(view, "input[name='ballot[possible_answers][1][value]'][value=Red]")
    end

    test "failure: a row error shows under its row while typing", ~M{view} do
      too_long = String.duplicate("a", 501)

      view
      |> form("#ballot-form")
      |> render_change(%{
        ballot: %{possible_answers: %{"0" => %{value: "Dune"}, "1" => %{value: too_long}}}
      })

      assert has_element?(view, answer_feedback_selector(1), "should be at most 500 character(s)")

      view
      |> form("#ballot-form")
      |> render_change(%{
        ballot: %{possible_answers: %{"0" => %{value: "Dune"}, "1" => %{value: "dune"}}}
      })

      assert has_element?(view, answer_feedback_selector(1), "repeats an earlier answer")
    end

    test "success: typing doesn't show the fewer-than-two or blank row errors", ~M{view} do
      view
      |> form("#ballot-form")
      |> render_change(%{
        ballot: %{possible_answers: %{"0" => %{value: "Dune"}, "1" => %{value: ""}}}
      })

      refute has_element?(view, "#possible-answers-errors")
      refute has_element?(view, answer_feedback_selector(1), "can't be blank")
    end

    test "failure: a repeated answer shows an error under the repeating row", ~M{view} do
      render_form_submit(view, %{
        possible_answers: %{"0" => %{value: "Dune"}, "1" => %{value: "dune"}}
      })

      assert has_element?(view, answer_feedback_selector(1), "repeats an earlier answer")
      refute has_element?(view, answer_feedback_selector(0), "repeats an earlier answer")
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
             } =
               updated_ballot =
               RankedVoting.get_ballot_by_url_slug_and_secret!("new-url-slug", secret)

      assert Ballot.possible_answer_values(updated_ballot) == ["purple", "pink", "yellow"]

      # The form's hidden id inputs keep each edited answer's identity.
      assert Enum.map(updated_ballot.possible_answers, & &1.id) ==
               Enum.map(Enum.take(ballot.possible_answers, 3), & &1.id)
    end

    test "success: rows can be dragged by a handle inside the sortable list", ~M{view} do
      assert has_element?(view, "#possible-answer-rows[phx-hook=SortableInputsFor]")
      assert has_element?(view, "#possible-answer-rows [data-handle]")
    end

    test "success: the move buttons are wired for the sortable list", ~M{view} do
      assert has_element?(view, "#move-possible-answer-up-1[data-move=up][data-index='1']")
      assert has_element?(view, "#move-possible-answer-down-1[data-move=down][data-index='1']")
    end

    test "success: the first row can't move up and the last row can't move down", ~M{view} do
      assert has_element?(view, "#move-possible-answer-up-0[disabled]")
      refute has_element?(view, "#move-possible-answer-down-0[disabled]")
      refute has_element?(view, "#move-possible-answer-up-4[disabled]")
      assert has_element?(view, "#move-possible-answer-down-4[disabled]")
    end

    test "success: adding an answer moves the disabled down button to the new last row",
         ~M{view} do
      reorder(view, ["0", "1", "2", "3", "4", "new"])

      refute has_element?(view, "#move-possible-answer-down-4[disabled]")
      assert has_element?(view, "#move-possible-answer-down-5[disabled]")
    end

    test "success: a reordered list moves the answers", ~M{view} do
      reorder(view, ["1", "0", "2", "4", "3"])

      assert has_element?(view, answer_row_selector(0, "Tuesday"))
      assert has_element?(view, answer_row_selector(1, "Monday"))
      assert has_element?(view, answer_row_selector(2, "Wednesday"))
      assert has_element?(view, answer_row_selector(3, "Friday"))
      assert has_element?(view, answer_row_selector(4, "Thursday"))
    end

    test "success: reordering keeps what the ballot owner typed", ~M{view} do
      view
      |> form("#ballot-form")
      |> render_change(%{
        ballot: %{
          possible_answers: %{"1" => %{value: "Taco Tuesday"}},
          possible_answers_sort: ["1", "0", "2", "3", "4"]
        }
      })

      assert has_element?(view, answer_row_selector(0, "Taco Tuesday"))
      assert has_element?(view, answer_row_selector(1, "Monday"))
    end

    test "success: a new answer moved to the top saves first", ~M{view, ballot} do
      reorder(view, ["0", "1", "2", "3", "4", "new"])

      view
      |> form("#ballot-form")
      |> render_change(%{
        ballot: %{
          possible_answers: %{"5" => %{value: "Sunday"}},
          possible_answers_sort: ["5", "0", "1", "2", "3", "4"]
        }
      })

      assert {:error, {:redirect, _redirect}} =
               view
               |> form("#ballot-form")
               |> render_submit()

      updated_ballot = RankedVoting.get_ballot!(ballot.id)

      assert Ballot.possible_answer_values(updated_ballot) ==
               ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

      assert tl(Enum.map(updated_ballot.possible_answers, & &1.id)) ==
               Enum.map(ballot.possible_answers, & &1.id)
    end

    test "success: saving after a reorder keeps the new order and each answer's id",
         ~M{view, ballot} do
      reorder(view, ["0", "1", "2", "4", "3"])

      assert {:error, {:redirect, _redirect}} =
               view
               |> form("#ballot-form")
               |> render_submit()

      updated_ballot = RankedVoting.get_ballot!(ballot.id)

      assert Ballot.possible_answer_values(updated_ballot) ==
               ["Monday", "Tuesday", "Wednesday", "Friday", "Thursday"]

      [monday, tuesday, wednesday, thursday, friday] = Enum.map(ballot.possible_answers, & &1.id)

      assert Enum.map(updated_ballot.possible_answers, & &1.id) ==
               [monday, tuesday, wednesday, friday, thursday]
    end

    test "success: clearing an existing answer while typing keeps the editor up", ~M{view} do
      view
      |> form("#ballot-form")
      |> render_change(%{ballot: %{possible_answers: %{"0" => %{value: ""}}}})

      assert has_element?(view, "#ballot_possible_answers_0_value")
      refute has_element?(view, answer_feedback_selector(0), "can't be blank")
    end

    test "failure: a failed save keeps the minimum number of answer rows", ~M{view} do
      render_form_submit(view, %{
        possible_answers: %{
          "0" => %{value: "Monday"},
          "1" => %{value: ""},
          "2" => %{value: ""},
          "3" => %{value: ""},
          "4" => %{value: ""}
        }
      })

      assert has_element?(view, "#possible-answers-errors", "must have at least two answers")
      assert has_element?(view, "#ballot_possible_answers_0_value[value=Monday]")
      assert has_element?(view, "#ballot_possible_answers_1_value")
      refute has_element?(view, "#ballot_possible_answers_2_value")
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

  # Dragging a row or pressing a move button reorders the hidden sort inputs in
  # the browser. The form's change event then sends the new order.
  defp reorder(view, sort) do
    view
    |> form("#ballot-form")
    |> render_change(%{ballot: %{possible_answers_sort: sort}})
  end

  # Rows keep their DOM ids when they move, so these tests find a row by its
  # input name.
  defp answer_row_selector(index, value) do
    "input[name='ballot[possible_answers][#{index}][value]'][value='#{value}']"
  end

  defp answer_feedback_selector(index) do
    feedback_selector("possible_answers][#{index}][value")
  end
end
