defmodule FlickWeb.LogScrubberFilterTest do
  use ExUnit.Case, async: true

  alias FlickWeb.LogScrubber

  test "replaces the user info in a URL" do
    assert scrub("GET https://admin:o'brien@rankedvote.app/admin") ==
             "GET https://[FILTERED]@rankedvote.app/admin"
  end

  test "replaces the user info in every URL in a message" do
    assert scrub(~s(%{"0" => "https://a:b@x.app/1", "1" => "http://c:d@x.app/2"})) ==
             ~s(%{"0" => "https://[FILTERED]@x.app/1", "1" => "http://[FILTERED]@x.app/2"})
  end

  test "leaves a URL without user info alone" do
    message = "https://rankedvote.app/ballot/abc?ref=a@b.com#c@d"

    assert scrub(message) == message
  end

  test "leaves a report message alone" do
    event = %{level: :info, msg: {:report, %{url: "https://a:b@x.app"}}, meta: %{}}

    assert LogScrubber.filter(event, []) == event
  end

  defp scrub(message) do
    event = %{level: :info, msg: {:string, message}, meta: %{}}
    %{msg: {:string, scrubbed}} = LogScrubber.filter(event, [])
    scrubbed
  end
end
