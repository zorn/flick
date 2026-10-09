defmodule FlickWeb.MetricsTest do
  use FlickWeb.ConnCase, async: true

  test "rejects a request without credentials", %{conn: conn} do
    conn = get(conn, "/metrics")

    assert response(conn, 401)
  end

  test "rejects a request with the wrong password", %{conn: conn} do
    conn =
      conn
      |> put_req_header(
        "authorization",
        Plug.BasicAuth.encode_basic_auth("flick-metrics", "wrong")
      )
      |> get("/metrics")

    assert response(conn, 401)
  end

  test "serves Flick's own metrics with the right credentials", %{conn: conn} do
    ballot = published_ballot_fixture(%{possible_answers: ["Pizza", "Tacos"]})

    {:ok, _vote} =
      Flick.RankedVoting.create_vote(ballot, %{"ranked_answers" => [%{"value" => "Pizza"}]})

    conn =
      conn
      |> put_req_header(
        "authorization",
        Plug.BasicAuth.encode_basic_auth("flick-metrics", "unsafe-metrics-password")
      )
      |> get("/metrics")

    # PromEx aggregates across async tests, so assert the series exists, not its count.
    assert response(conn, 200) =~
             ~s(flick_ranked_voting_create_vote_duration_milliseconds_count{result="ok"})
  end
end
