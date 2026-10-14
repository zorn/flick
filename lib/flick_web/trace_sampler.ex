defmodule FlickWeb.TraceSampler do
  @moduledoc """
  Decides at the start of each trace whether to keep it.

  It drops two kinds of request and keeps everything else:

  * `/metrics`, because Prometheus scrapes it every 15 seconds.
  * `/live/websocket` and `/live/longpoll`, LiveView's socket transports. They
    skip the endpoint's plugs, so their spans would keep a CSRF token and the
    voter's IP address. The LiveView spans that follow on the socket still get
    traced.
  """

  @behaviour :otel_sampler

  @dropped_paths ["/metrics", "/live/websocket", "/live/longpoll"]

  @impl :otel_sampler
  def setup(_opts), do: []

  @impl :otel_sampler
  def description(_config), do: "FlickWeb.TraceSampler"

  @impl :otel_sampler
  def should_sample(ctx, _trace_id, _links, _name, _kind, attributes, _config) do
    tracestate = ctx |> :otel_tracer.current_span_ctx() |> :otel_span.tracestate()

    if attributes[:"url.path"] in @dropped_paths do
      {:drop, [], tracestate}
    else
      {:record_and_sample, [], tracestate}
    end
  end
end
