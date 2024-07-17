defmodule FlickWeb.Ballots.EditorLiveTest do
  use FlickWeb.ConnCase, async: true

  test "renders create ballot form", %{conn: conn} do
    assert {:ok, view, _html} = live(conn, ~p"/ballots/new")
    assert has_element?(view, "#ballot_question_title")
    assert has_element?(view, "#ballot_possible_answers")
  end
end
