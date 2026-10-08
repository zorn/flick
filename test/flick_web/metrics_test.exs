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

  test "serves Prometheus metrics with the right credentials", %{conn: conn} do
    conn =
      conn
      |> put_req_header(
        "authorization",
        Plug.BasicAuth.encode_basic_auth("flick-metrics", "unsafe-metrics-password")
      )
      |> get("/metrics")

    assert response(conn, 200) =~ "# TYPE flick_prom_ex_"
  end
end
