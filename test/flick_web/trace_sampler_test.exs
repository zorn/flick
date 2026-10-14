defmodule FlickWeb.TraceSamplerTest do
  use ExUnit.Case, async: true

  alias FlickWeb.TraceSampler

  for path <- ["/metrics", "/live/websocket", "/live/longpoll"] do
    test "drops a trace that starts at #{path}" do
      assert {:drop, [], _tracestate} = sample(unquote(path))
    end
  end

  test "keeps a trace that starts at a ballot page" do
    assert {:record_and_sample, [], _tracestate} = sample("/ballot/lunch")
  end

  defp sample(path) do
    TraceSampler.should_sample(:otel_ctx.new(), 1, [], "GET", :server, %{"url.path": path}, [])
  end
end
