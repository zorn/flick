defmodule FlickWeb.HealthTest do
  use FlickWeb.ConnCase, async: true

  test "answers 200 when the database is reachable", %{conn: conn} do
    conn = get(conn, "/health")

    assert response(conn, 200)
  end

  test "leaves methods other than GET and HEAD to the router", %{conn: conn} do
    conn = post(conn, "/health")

    assert response(conn, 404)
  end

  @tag :capture_log
  test "answers 503 when the database is unreachable", %{conn: conn} do
    # `ConnTest` runs the endpoint in this process, so the dynamic repo applies
    # to the request. The dynamic repo points at a port where nothing listens.
    {:ok, socket} = :gen_tcp.listen(0, [])
    {:ok, closed_port} = :inet.port(socket)
    :ok = :gen_tcp.close(socket)

    unreachable_repo =
      start_supervised!(
        {Flick.Repo,
         name: nil,
         port: closed_port,
         pool: DBConnection.ConnectionPool,
         pool_size: 1,
         queue_target: 10,
         queue_interval: 10}
      )

    Flick.Repo.put_dynamic_repo(unreachable_repo)

    conn = get(conn, "/health")

    assert response(conn, 503)
  end
end
