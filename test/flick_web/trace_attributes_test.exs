defmodule FlickWeb.TraceAttributesTest do
  # The span exporter and the sandbox's shared mode are both global, so this
  # module can't run beside other tests.
  use Flick.DataCase, async: false

  import Support.Fixtures.BallotFixture

  require Record

  Record.defrecordp(:span, Record.extract(:span, from_lib: "opentelemetry/include/otel_span.hrl"))

  # A library upgrade can add an attribute that carries voter data, and
  # FlickWeb.TraceScrubber only drops keys it knows. Review any new key before
  # adding it here.
  @known_keys ~w(
    db.instance db.name db.system db.type db.url
    decode_time_microseconds query_time_microseconds queue_time_microseconds
    total_time_microseconds source
    http.request.method http.response.status_code http.route
    network.protocol.version server.address server.port url.path url.scheme
    phoenix.action phoenix.plug
  )a

  test "a request through Bandit, Phoenix, and Ecto exports only known keys" do
    ballot = published_ballot_fixture()
    # After the fixture, so its queries stay out of the export.
    :otel_simple_processor.set_exporter(FlickWeb.TraceScrubber, {:otel_exporter_pid, self()})

    port = start_server()

    assert %{status: 200} = Req.get!("http://localhost:#{port}/ballot/#{ballot.url_slug}")

    attributes = receive_spans()

    assert attributes |> Enum.flat_map(&Map.keys/1) |> Enum.uniq() |> Enum.sort() ==
             Enum.sort(@known_keys)

    # Ecto drops `:url` from the repo's config, so this never holds the
    # database password.
    assert attributes |> Enum.map(& &1[:"db.url"]) |> Enum.reject(&is_nil/1) |> Enum.uniq() ==
             ["ecto://localhost"]
  end

  test "an admin path with a percent-encoded secret exports no secret" do
    ballot = ballot_fixture()
    :otel_simple_processor.set_exporter(FlickWeb.TraceScrubber, {:otel_exporter_pid, self()})
    port = start_server()

    # Phoenix decodes the path before routing, so this reaches the editor.
    secret = String.replace(ballot.secret, "-", "%2D")
    url = "http://localhost:#{port}/ballot/#{ballot.url_slug}/#{secret}/edit"
    assert %{status: 200} = Req.get!(url)

    paths = receive_spans() |> Enum.map(& &1[:"url.path"]) |> Enum.reject(&is_nil/1)

    assert paths == ["/ballot/#{ballot.url_slug}/:uuid/edit"]
  end

  defp start_server do
    server = start_supervised!({Bandit, plug: FlickWeb.Endpoint, port: 0, startup_log: false})
    {:ok, {_address, port}} = ThousandIsland.listener_info(server)
    port
  end

  # Bandit's request span is the root, and it ends after every span inside it.
  defp receive_spans(acc \\ []) do
    assert_receive {:span, span(attributes: attributes, parent_span_id: parent)}
    acc = [:otel_attributes.map(attributes) | acc]

    if parent == :undefined, do: acc, else: receive_spans(acc)
  end
end
