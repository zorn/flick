defmodule FlickWeb.TraceRedactionTest do
  # Every test shares one span exporter, so a concurrent test's spans would
  # reach this process.
  use FlickWeb.ConnCase, async: false

  require OpenTelemetry.Tracer
  require Record

  Record.defrecordp(:span, Record.extract(:span, from_lib: "opentelemetry/include/otel_span.hrl"))

  setup do
    :otel_simple_processor.set_exporter(:otel_exporter_pid, self())
  end

  test "overwrites the voter's IP address and the ballot's secret", %{conn: conn} do
    ballot = ballot_fixture()

    attributes = traced_get(conn, ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}/edit")

    assert attributes[:"client.address"] == "redacted"
    assert attributes[:"network.peer.address"] == "redacted"
    assert attributes[:"url.path"] == "/ballot/#{ballot.url_slug}/:uuid/edit"
  end

  test "overwrites the query string", %{conn: conn} do
    ballot = ballot_fixture()

    attributes =
      traced_get(conn, ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}/edit?ref=newsletter")

    assert attributes[:"url.query"] == "redacted"
  end

  test "adds no query string when the request has none", %{conn: conn} do
    ballot = ballot_fixture()

    attributes = traced_get(conn, ~p"/ballot/#{ballot.url_slug}/#{ballot.secret}/edit")

    refute Map.has_key?(attributes, :"url.query")
  end

  # Phoenix.ConnTest skips Bandit, which starts the request span in production.
  # This starts that span with the attributes Bandit records, then runs the
  # endpoint inside it.
  defp traced_get(conn, path_and_query) do
    %URI{path: path, query: query} = URI.parse(path_and_query)

    attributes =
      %{
        "client.address": "203.0.113.7",
        "network.peer.address": "203.0.113.7",
        "url.path": path
      }
      |> then(&if(query, do: Map.put(&1, :"url.query", query), else: &1))

    span_id =
      OpenTelemetry.Tracer.with_span "request", %{attributes: attributes} do
        get(conn, path_and_query)
        OpenTelemetry.Span.span_id(OpenTelemetry.Tracer.current_span_ctx())
      end

    assert_receive {:span, span(span_id: ^span_id, attributes: exported)}
    :otel_attributes.map(exported)
  end
end
