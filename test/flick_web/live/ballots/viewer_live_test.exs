defmodule FlickWeb.Ballots.ViewerLiveTest do
  @moduledoc """
  Verifies the expected logic of `FlickWeb.Ballots.ViewerLive`.

  Viewer: http://localhost:4000/<url-slug>/<secret>
  """

  use FlickWeb.ConnCase, async: true

  alias Flick.DateTimeFormatter

  test "renders ballot details", ~M{conn} do
    ballot = ballot_fixture()
    assert {:ok, view, _html} = live(conn, view_path(ballot))
    assert has_element?(view, "#ballot-question-title", ballot.question_title)
    assert has_element?(view, "#ballot-possible-answers", ballot.possible_answers)
    assert has_element?(view, "#ballot-url-slug", ballot.url_slug)
  end

  test "responds with 404 when no ballot is found", ~M{conn} do
    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/ballot/unknown-slug")
    end
  end

  test "presents edit button for non published ballots", ~M{conn} do
    ballot = ballot_fixture()
    assert {:ok, view, _html} = live(conn, view_path(ballot))
    assert has_element?(view, "#edit-ballot-button")
  end

  test "hides edit button for non published ballots", ~M{conn} do
    published_ballot = published_ballot_fixture()
    {:ok, view, _html} = live(conn, view_path(published_ballot))
    refute has_element?(view, "#edit-ballot-button")
  end

  test "presents the publish button for non published ballots", ~M{conn} do
    ballot = ballot_fixture()
    assert {:ok, view, _html} = live(conn, ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}")
    assert has_element?(view, "#publish-ballot-button")
  end

  test "hides the publish button for published ballots", ~M{conn} do
    published_ballot = published_ballot_fixture()
    {:ok, view, _html} = live(conn, view_path(published_ballot))
    refute has_element?(view, "#publish-ballot-button")
  end

  test "presents the vote link for a published ballot", ~M{conn} do
    published_ballot = published_ballot_fixture()
    {:ok, view, _html} = live(conn, view_path(published_ballot))
    assert has_element?(view, "a[href='/ballot/#{published_ballot.url_slug}']")
  end

  test "displays a formatted `DateTime` value for a draft proposal", ~M{conn} do
    # This is likely to be flaky because the concept of
    # `now` has space to change between when the time the `expected_message` is
    # created and when the data actually hits the the database. To solve this
    # we'd probably want to make a legit field for `created_at` (that can be
    # assigned) and not make assumptions about using `inserted_at` which the
    # database owns. This is discussed inside of
    # `docs/decisions/1-timestamps.md` but is being ignored for now.
    now = DateTime.utc_now()
    expected_now_string = DateTimeFormatter.display_string(now, "UTC")
    expected_message = "Your ballot was created on #{expected_now_string}."
    draft_ballot = ballot_fixture()
    {:ok, view, _html} = live(conn, view_path(draft_ballot))
    assert has_element?(view, "p", expected_message)
  end

  test "displays a formatted `DateTime` value for a published proposal", ~M{conn} do
    now = DateTime.utc_now()
    expected_now_string = DateTimeFormatter.display_string(now, "UTC")
    expected_message = "Your ballot was published on #{expected_now_string}."
    published_ballot = published_ballot_fixture(%{}, now)
    {:ok, view, _html} = live(conn, view_path(published_ballot))
    assert has_element?(view, "p", expected_message)
  end

  test "displays a formatted `DateTime` value for a closed proposal", ~M{conn} do
    now = DateTime.utc_now()
    expected_now_string = DateTimeFormatter.display_string(now, "UTC")
    expected_message = "Your ballot was closed on #{expected_now_string}."
    closed_ballot = closed_ballot_fixture(%{}, now)
    {:ok, view, _html} = live(conn, view_path(closed_ballot))
    assert has_element?(view, "p", expected_message)
  end

  defp view_path(ballot) do
    ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}"
  end
end
