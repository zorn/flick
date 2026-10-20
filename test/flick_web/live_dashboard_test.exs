defmodule FlickWeb.LiveDashboardTest do
  use FlickWeb.ConnCase, async: true

  test "rejects a request without credentials", ~M{conn} do
    conn = get(conn, "/admin/dashboard")

    assert response(conn, 401)
  end

  test "shows database stats for Flick.Repo", ~M{conn} do
    conn =
      conn
      |> put_req_header(
        "authorization",
        Plug.BasicAuth.encode_basic_auth("flick-admin", "unsafe-password")
      )
      |> get("/admin/dashboard/ecto_stats?repo=Flick.Repo")

    document = conn |> html_response(200) |> LazyHTML.from_document()

    # Each ecto_psql_extras query gets a tab; without the library the page shows an error instead.
    assert document |> LazyHTML.query("a[href*='nav=table_size']") |> Enum.count() == 1
  end

  test "serves the dashboard with scripts that satisfy the CSP nonce", ~M{conn} do
    conn =
      conn
      |> put_req_header(
        "authorization",
        Plug.BasicAuth.encode_basic_auth("flick-admin", "unsafe-password")
      )
      |> get("/admin/dashboard/home")

    html = html_response(conn, 200)
    [csp] = get_resp_header(conn, "content-security-policy")
    [_, nonce] = Regex.run(~r/script-src 'nonce-([^']+)'/, csp)

    scripts = html |> LazyHTML.from_document() |> LazyHTML.query("script")
    refute Enum.empty?(scripts)

    for script <- scripts do
      assert LazyHTML.attribute(script, "nonce") == [nonce]
    end
  end
end
