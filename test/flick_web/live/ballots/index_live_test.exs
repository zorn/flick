defmodule FlickWeb.Ballots.IndexLiveTest do
  @moduledoc """
  Verifies logic for the live view `FlickWeb.Ballots.IndexLive`.
  """

  use FlickWeb.ConnCase, async: true

  describe "without admin authentication" do
    test "responds with 401", ~M{conn} do
      # A more expected approach to test this logic would be to use the
      # `Phoenix.LiveViewTest.live/2` function, but this throws when using basic
      # auth. Instead, we'll do a more specific `GET` test.
      conn = get(conn, ~p"/admin/ballots")
      {_header_name, header_value} = List.keyfind(conn.resp_headers, "www-authenticate", 0)
      assert conn.status == 401
      assert header_value =~ "Basic"
    end
  end

  describe "with admin authentication" do
    setup ~M{conn} do
      basic_auth = Plug.BasicAuth.encode_basic_auth("flick-admin", "unsafe-password")
      conn = put_req_header(conn, "authorization", basic_auth)
      {:ok, conn: conn}
    end

    test "renders list of ballots", ~M{conn} do
      ballots = Enum.map(1..3, fn _ -> ballot_fixture() end)
      assert {:ok, view, _html} = live(conn, ~p"/admin/ballots")
      assert has_element?(view, "tbody#ballots")

      for ballot <- ballots do
        row_selector = "tbody#ballots tr#ballot-row-#{ballot.id}"
        assert has_element?(view, row_selector, ballot.question_title)
        assert has_element?(view, row_selector, "Draft")
      end
    end
  end
end
