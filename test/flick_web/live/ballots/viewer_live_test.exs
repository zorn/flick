defmodule FlickWeb.Ballots.ViewerLiveTest do
  use FlickWeb.ConnCase, async: true

  test "renders ballot details", ~M{conn} do
    ballot = ballot_fixture()
    assert {:ok, view, _html} = live(conn, ~p"/#{ballot.url_slug}/#{ballot.id}")
    assert has_element?(view, "#ballot-question-title", ballot.question_title)
  end

  test "responds with 404 when no ballot is found", ~M{conn} do
    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/ballots/#{Ecto.UUID.generate()}")
    end
  end
end
