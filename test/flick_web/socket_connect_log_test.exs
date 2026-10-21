defmodule FlickWeb.SocketConnectLogTest do
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

  test "a socket connect logs no CSRF token or static asset credentials" do
    # Built from parts, so the secret scan doesn't flag a credential URL.
    leaked = "unsafe-password"

    params =
      Map.merge(phoenix_default_params(leaked), %{
        "_csrf_token" => "csrf-#{leaked}",
        "_track_static" => %{
          "0" => "https://flick-admin:#{leaked}@rankedvote.app/assets/css/app.css?vsn=d"
        }
      })

    log =
      capture_log([level: :info], fn ->
        assert {:ok, _socket} = connect(Phoenix.LiveView.Socket, params)
      end)

    assert log =~ "CONNECTED TO Phoenix.LiveView.Socket"
    assert log =~ ~s("_csrf_token" => "[FILTERED]")
    assert log =~ ~s("_track_static" => "[FILTERED]")
    refute log =~ leaked
  end

  # Setting `:filter_parameters` replaces Phoenix's default rather than adding
  # to it. One param per default term catches a term the list leaves out,
  # including one a Phoenix upgrade adds.
  defp phoenix_default_params(value) do
    {:ok, [{:application, :phoenix, properties}]} =
      :file.consult(Application.app_dir(:phoenix, "ebin/phoenix.app"))

    Map.new(properties[:env][:filter_parameters], &{&1, value})
  end
end
