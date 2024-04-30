defmodule FlickWeb.Ballots.ViewerLiveTest do
  use FlickWeb.ConnCase, async: true

  test "renders ballot details", %{conn: conn} do
    ballot = ballot_fixture()
    assert {:ok, view, _html} = live(conn, ~p"/ballots/#{ballot}")
    assert has_element?(view, "#ballot-title", ballot.title)
  end

  test "responds with 404 when no ballot is found", %{conn: conn} do
    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/ballots/#{Ecto.UUID.generate()}")
    end
  end
end
