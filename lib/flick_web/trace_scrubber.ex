defmodule FlickWeb.TraceScrubber do
  @moduledoc """
  Wraps the trace exporter and strips voter data from every span before it
  leaves Flick.

  Bandit records the voter's IP address, user agent, path, and query string
  on each request span. Ballot paths carry the ballot's secret. Exception
  messages, stacktraces, and error statuses can quote a path, a LiveView
  event's params, or a row's values. This module removes all of them, and
  replaces any UUID with `:uuid`.

  The scrubbing happens here, not in a span processor, because the SDK hands
  every processor the same unchanged span. The exporter is the one place that
  can change what Tempo receives.
  """

  @behaviour :otel_exporter_traces

  require Record

  Record.defrecordp(:span, Record.extract(:span, from_lib: "opentelemetry/include/otel_span.hrl"))

  Record.defrecordp(
    :event,
    Record.extract(:event, from_lib: "opentelemetry/include/otel_span.hrl")
  )

  Record.defrecordp(
    :status,
    Record.extract(:status, from_lib: "opentelemetry_api/include/opentelemetry.hrl")
  )

  # The SDK keeps these two records private, in `otel_events.erl` and
  # `otel_attributes.erl`, so `Record.extract/2` can't read them. The tests
  # fail if their shape changes.
  Record.defrecordp(:events, [
    :count_limit,
    :attribute_per_event_limit,
    :attribute_value_length_limit,
    :dropped,
    :list
  ])

  Record.defrecordp(:attributes, [:count_limit, :value_length_limit, :dropped, :map])

  @dropped_keys ~w(
    client.address
    client.port
    network.peer.address
    network.peer.port
    user_agent.original
    url.query
    exception.message
    exception.stacktrace
  )

  # Bandit records the raw path, and Phoenix decodes it before routing, so a
  # secret still works with any of its characters percent-encoded. Each
  # character here matches itself or its `%XX` form.
  hex = "(?:[0-9a-f]|%3[0-9]|%[46][1-6])"
  dash = "(?:-|%2d)"

  @uuid Regex.compile!(
          "#{hex}{8}#{dash}#{hex}{4}#{dash}#{hex}{4}#{dash}#{hex}{4}#{dash}#{hex}{12}",
          "i"
        )

  @impl :otel_exporter_traces
  def init(exporter) do
    case :otel_exporter.init(exporter) do
      :undefined -> :ignore
      inner -> {:ok, inner}
    end
  end

  @impl :otel_exporter_traces
  def export(spans_tid, resource, inner) do
    # The SDK's table is a duplicate bag keyed by instrumentation scope. A set
    # would keep only one span per library.
    scrubbed =
      :ets.new(__MODULE__, [:ets.info(spans_tid, :type), keypos: :ets.info(spans_tid, :keypos)])

    try do
      :ets.foldl(fn span, _acc -> :ets.insert(scrubbed, scrub(span)) end, true, spans_tid)
      :otel_exporter_traces.export(inner, scrubbed, resource)
    after
      :ets.delete(scrubbed)
    end
  end

  @impl :otel_exporter_traces
  def shutdown(inner), do: :otel_exporter.shutdown(inner)

  defp scrub(span) do
    events = span(span, :events)
    scrubbed_events = for event <- events(events, :list), do: scrub_event(event)

    span(span,
      attributes: scrub_attributes(span(span, :attributes)),
      events: events(events, list: scrubbed_events),
      status: scrub_status(span(span, :status))
    )
  end

  # Ecto sets a failed query's status message to the Postgres error, which
  # quotes the row's values.
  defp scrub_status(status(code: code)), do: status(code: code)
  defp scrub_status(status), do: status

  defp scrub_event(event) do
    event(event, attributes: scrub_attributes(event(event, :attributes)))
  end

  defp scrub_attributes(attributes) do
    map =
      for {key, value} <- attributes(attributes, :map),
          to_string(key) not in @dropped_keys,
          into: %{},
          do: {key, scrub_value(value)}

    attributes(attributes, map: map)
  end

  defp scrub_value(value) when is_binary(value), do: String.replace(value, @uuid, ":uuid")
  defp scrub_value(values) when is_list(values), do: Enum.map(values, &scrub_value/1)
  defp scrub_value(value), do: value
end
