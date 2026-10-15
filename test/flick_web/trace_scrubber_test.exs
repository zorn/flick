defmodule FlickWeb.TraceScrubberTest do
  # Every test shares one span exporter, so a concurrent test's spans would
  # reach this process.
  use ExUnit.Case, async: false

  require OpenTelemetry.Tracer
  require Record

  Record.defrecordp(:span, Record.extract(:span, from_lib: "opentelemetry/include/otel_span.hrl"))

  Record.defrecordp(
    :event,
    Record.extract(:event, from_lib: "opentelemetry/include/otel_span.hrl")
  )

  @secret "6f1c2a8e-4b7d-4e2a-9c3f-1d5e8b0a7c42"

  setup do
    :otel_simple_processor.set_exporter(FlickWeb.TraceScrubber, {:otel_exporter_pid, self()})
  end

  test "removes the voter's address, user agent, and query string" do
    attributes =
      export_span(%{
        "client.address": "203.0.113.7",
        "network.peer.address": "203.0.113.7",
        "network.peer.port": 52_114,
        "user_agent.original": "Mozilla/5.0 (Macintosh)",
        "url.query": "ref=newsletter",
        "http.request.method": "GET"
      })

    assert attributes == %{"http.request.method": "GET"}
  end

  test "replaces the ballot's secret in the path" do
    attributes = export_span(%{"url.path": "/ballot/lunch/#{@secret}/edit"})

    assert attributes[:"url.path"] == "/ballot/lunch/:uuid/edit"
  end

  test "replaces a secret with some or all of its characters percent-encoded" do
    mixed = String.replace(@secret, "-", "%2D")
    encoded = @secret |> String.to_charlist() |> Enum.map_join(&"%#{Integer.to_string(&1, 16)}")

    for secret <- [mixed, String.downcase(mixed), encoded] do
      attributes = export_span(%{"url.path": "/ballot/lunch/#{secret}/edit"})

      assert attributes[:"url.path"] == "/ballot/lunch/:uuid/edit"
    end
  end

  test "replaces the ballot's secret inside a list of values" do
    attributes = export_span(%{"http.request.header.referer": ["/ballot/lunch/#{@secret}/edit"]})

    assert attributes[:"http.request.header.referer"] == ["/ballot/lunch/:uuid/edit"]
  end

  test "keeps an error status but drops its message" do
    span_id =
      OpenTelemetry.Tracer.with_span "query" do
        OpenTelemetry.Tracer.set_status(
          OpenTelemetry.status(:error, "Key (secret)=(#{@secret}) already exists.")
        )

        OpenTelemetry.Span.span_id(OpenTelemetry.Tracer.current_span_ctx())
      end

    assert_receive {:span, span(span_id: ^span_id, status: status)}
    assert status == OpenTelemetry.status(:error, "")
  end

  test "keeps an exception's type but drops its message and stacktrace" do
    exception = %RuntimeError{message: "no route found for GET /ballot/lunch/#{@secret}/edits"}

    span_id =
      OpenTelemetry.Tracer.with_span "request", %{attributes: %{"url.path": "/ballot/lunch"}} do
        OpenTelemetry.Tracer.record_exception(exception, [])
        OpenTelemetry.Span.span_id(OpenTelemetry.Tracer.current_span_ctx())
      end

    assert_receive {:span, span(span_id: ^span_id, events: events)}
    [exception_event] = :otel_events.list(events)

    assert :otel_attributes.map(event(exception_event, :attributes)) == %{
             "exception.type": "Elixir.RuntimeError"
           }
  end

  test "exports every span in a batch, even from the same library" do
    spans = :ets.new(:batch, [:duplicate_bag, keypos: span(:instrumentation_scope) + 1])
    scope = :opentelemetry.instrumentation_scope("opentelemetry_bandit", "0.3.0", :undefined)

    for span_id <- [1, 2] do
      :ets.insert(
        spans,
        span(
          span_id: span_id,
          instrumentation_scope: scope,
          attributes: :otel_attributes.new(%{}, 128, :infinity),
          events: :otel_events.new(128, 128, :infinity)
        )
      )
    end

    {:ok, inner} = FlickWeb.TraceScrubber.init({:otel_exporter_pid, self()})
    FlickWeb.TraceScrubber.export(spans, :otel_resource.create([]), inner)

    assert_receive {:span, span(span_id: 1)}
    assert_receive {:span, span(span_id: 2)}
  end

  defp export_span(attributes) do
    span_id =
      OpenTelemetry.Tracer.with_span "request", %{attributes: attributes} do
        OpenTelemetry.Span.span_id(OpenTelemetry.Tracer.current_span_ctx())
      end

    assert_receive {:span, span(span_id: ^span_id, attributes: exported)}
    :otel_attributes.map(exported)
  end
end
