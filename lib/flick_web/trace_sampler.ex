defmodule FlickWeb.TraceSampler do
  @moduledoc """
  Decides at the start of each trace whether to keep it.

  It drops requests that say nothing about Flick's behavior, and keeps
  everything else:

  * `/metrics`, because Prometheus scrapes it every 15 seconds.
  * `/health`, because Render checks it every few seconds.
  * `/live/websocket` and `/live/longpoll`, LiveView's socket transports. The
    LiveView spans that follow on the socket still get traced.
  * Static files, such as `/assets/app.js` and `/favicon.ico`.
  """

  @behaviour :otel_sampler

  @dropped_paths ["/metrics", "/health", "/live/websocket", "/live/longpoll"]

  @impl :otel_sampler
  def setup(_opts), do: []

  @impl :otel_sampler
  def description(_config), do: "FlickWeb.TraceSampler"

  @impl :otel_sampler
  def should_sample(ctx, _trace_id, _links, _name, _kind, attributes, _config) do
    tracestate = ctx |> :otel_tracer.current_span_ctx() |> :otel_span.tracestate()

    if dropped?(attributes[:"url.path"]) do
      {:drop, [], tracestate}
    else
      {:record_and_sample, [], tracestate}
    end
  end

  defp dropped?(path) when is_binary(path) do
    [first_segment | _rest] = path |> String.trim_leading("/") |> String.split("/")
    path in @dropped_paths or first_segment in FlickWeb.static_paths()
  end

  defp dropped?(_path), do: false
end
