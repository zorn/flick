defmodule FlickWeb.IndexLiveTest do
  @moduledoc """
  Verifies the expected logic of `FlickWeb.IndexLive`.

  http://localhost:4000/
  """

  use FlickWeb.ConnCase, async: true

  test "renders the index page", ~M{conn} do
    assert {:ok, _view, _html} = live(conn, ~p"/")
  end

  test "contains welcome copy", ~M{conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    expected_welcome_copy =
      "Flick is an application that allows you to create ballots that capture ranked votes."

    assert view |> element("#welcome-copy") |> render() =~ expected_welcome_copy
  end

  test "contains link to create a ballot", ~M{conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, "a[href='/ballot/new']", "Create a ballot")
  end
end
