defmodule Support.QueryCounter do
  @moduledoc """
  Counts the `Flick.Repo` queries that a process makes against one table.

  Telemetry handlers are global. The handler sends the test process every query
  against the table, tagged with the process that made it. A test counts only
  the queries of its own processes, so async tests do not interfere.
  """

  use Boundary, top_level?: true, deps: []

  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc """
  Sends the test process a message for each `Flick.Repo` query against `source`.
  """
  @spec attach(String.t()) :: :ok
  def attach(source) do
    handler_id = {__MODULE__, self()}

    :ok =
      :telemetry.attach(
        handler_id,
        [:flick, :repo, :query],
        &__MODULE__.forward_query/4,
        %{test_pid: self(), source: source}
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)
  end

  @doc """
  Returns how many queries `pid` has made since the last count. Each count
  consumes the queries it reports.

  For another process, `pid` must be a `GenServer`, such as a LiveView.
  """
  @spec count(pid()) :: non_neg_integer()
  def count(pid) do
    # Erlang orders messages between one sender and one receiver. Once `pid`
    # replies here, every query message it sent earlier has arrived.
    if pid != self(), do: :sys.get_state(pid)

    drain(pid)
  end

  defp drain(pid) do
    receive do
      {__MODULE__, ^pid} -> 1 + drain(pid)
    after
      0 -> 0
    end
  end

  @doc false
  @spec forward_query(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata(),
          map()
        ) :: :ok
  def forward_query(_event, _measurements, %{source: source}, %{source: source} = config) do
    send(config.test_pid, {__MODULE__, self()})
    :ok
  end

  def forward_query(_event, _measurements, _metadata, _config), do: :ok
end
