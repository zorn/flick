defmodule FlickWeb.TraceSamplerTest do
  use ExUnit.Case, async: true

  alias FlickWeb.TraceSampler

  for path <- [
        "/metrics",
        "/live/websocket",
        "/live/longpoll",
        "/assets/app.js",
        "/favicon.ico"
      ] do
    test "drops a trace that starts at #{path}" do
      assert {:drop, [], _tracestate} = sample(unquote(path))
    end
  end

  for path <- ["/", "/ballot/lunch"] do
    test "keeps a trace that starts at #{path}" do
      assert {:record_and_sample, [], _tracestate} = sample(unquote(path))
    end
  end

  defp sample(path) do
    TraceSampler.should_sample(:otel_ctx.new(), 1, [], "GET", :server, %{"url.path": path}, [])
  end
end
