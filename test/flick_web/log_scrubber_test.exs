defmodule FlickWeb.LogScrubberTest do
  # The test logs at `info` globally, which would let other tests' logs
  # through.
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Phoenix.ChannelTest

  @endpoint FlickWeb.Endpoint

  setup do
    # Test config logs at `warning`, and Phoenix logs socket connects at `info`.
    # `capture_log/2` never captures below the global level.
    level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: level) end)
  end

  test "a socket connect logs its static asset URLs without their credentials" do
    # Built from parts, so the secret scan doesn't flag a credential URL.
    leaked = "unsafe-password"

    params = %{
      "_track_static" => %{
        "0" => "https://flick-admin:#{leaked}@rankedvote.app/assets/css/app.css?vsn=d"
      }
    }

    log =
      capture_log([level: :info], fn ->
        assert {:ok, _socket} = connect(Phoenix.LiveView.Socket, params)
      end)

    assert log =~ "CONNECTED TO Phoenix.LiveView.Socket"
    assert log =~ "https://[FILTERED]@rankedvote.app/assets/css/app.css?vsn=d"
    refute log =~ leaked
  end
end
