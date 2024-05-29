defmodule FlickWeb.Ballots.IndexLiveTest do
  use FlickWeb.ConnCase, async: true

  test "renders list of ballots", %{conn: conn} do
    ballots = Enum.map(1..3, fn _ -> ballot_fixture() end)
    assert {:ok, view, _html} = live(conn, ~p"/ballots")
    assert has_element?(view, "table#ballots")

    for ballot <- ballots do
      row_selector = "table#ballots tr#ballot-row-#{ballot.id}"
      assert has_element?(view, row_selector, ballot.title)
      assert has_element?(view, row_selector, "Not Published")
    end
  end
end
