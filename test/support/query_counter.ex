defmodule Support.QueryCounter do
  @moduledoc """
  Counts the `Flick.Repo` queries that a process makes against one table.

  Telemetry handlers are global, so the handler forwards every query against
  the table along with the process that made it. A test then counts only the
  queries from the processes it owns, which keeps it safe beside async tests.
  """

  use Boundary, top_level?: true, deps: []

  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc """
  Starts forwarding the test process every `Flick.Repo` query against `source`.
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
  Returns how many queries `pid` has made since the last count, and forgets
  them so that the next count starts from zero.
  """
  @spec count(pid()) :: non_neg_integer()
  def count(pid) do
    receive do
      {__MODULE__, ^pid} -> 1 + count(pid)
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
