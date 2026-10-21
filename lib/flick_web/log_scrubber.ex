defmodule FlickWeb.LogScrubber do
  @moduledoc """
  A `:logger` filter that replaces the user info in a URL in a log message
  with `[FILTERED]`.

  A browser that opens `/admin` through a `https://user:password@…` URL adds
  that user info to its static asset URLs. Phoenix logs those URLs when the
  LiveView socket connects, under `_track_static`. Phoenix's
  `filter_parameters` matches parameter names, not text inside a value, so it
  can't catch them.

  Elixir builds a lazy message before the filter runs, so the filter sees it as
  `{:string, chardata}`. The filter leaves report and format-string messages
  alone. Elixir turns a crash report into text only when a handler formats it,
  after every filter has run, so a crash report that quotes such a URL still
  logs it.
  """

  # Excluding `"` stops the match at the end of an inspected string. Browsers
  # always percent-encode `"` in user info.
  @user_info ~r{(?<=://)[^/?#@\s"]+@}

  @doc """
  Adds the filter to every log handler.
  """
  @spec install() :: :ok | {:error, term()}
  def install do
    :logger.add_primary_filter(__MODULE__, {&filter/2, []})
  end

  @doc false
  @spec filter(:logger.log_event(), term()) :: :logger.filter_return()
  def filter(%{msg: {:string, chardata}} = event, _extra) do
    %{event | msg: {:string, scrub(chardata)}}
  end

  def filter(event, _extra), do: event

  defp scrub(chardata) do
    Regex.replace(@user_info, IO.chardata_to_string(chardata), "[FILTERED]@")
  end
end
