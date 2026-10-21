defmodule Flick.Repo.VersionCheck do
  @moduledoc """
  Refuses to boot when `Flick.Repo` reaches a Postgres server on a major
  version other than `:postgres_major_version`.

  Dev and test connect to whatever server answers on the configured port, so
  without this check they can run on an older Postgres than production without
  anything noticing. Prod sets no expected version, so the check does nothing
  there.

  It runs as a child after `Flick.Repo` in the application's supervision tree.
  Its start function raises on a mismatch, which stops the application before
  the endpoint starts, and otherwise returns `:ignore`, so no process is left
  running.
  """

  @doc false
  @spec child_spec(term()) :: Supervisor.child_spec()
  def child_spec(_arg) do
    %{id: __MODULE__, start: {__MODULE__, :run, []}, restart: :temporary}
  end

  @doc false
  @spec run() :: :ignore
  def run do
    if expected_major = Application.get_env(:flick, :postgres_major_version) do
      %{rows: [[server_version_num]]} =
        Flick.Repo.query!("SHOW server_version_num", [], log: false)

      verify!(server_version_num, expected_major)
    end

    :ignore
  end

  @doc """
  Returns `:ok` when `server_version_num`, as Postgres reports it, is on
  `expected_major`, and raises otherwise.
  """
  @spec verify!(String.t(), pos_integer()) :: :ok
  def verify!(server_version_num, expected_major) do
    case div(String.to_integer(server_version_num), 10_000) do
      ^expected_major ->
        :ok

      actual_major ->
        raise """
        Flick.Repo reached Postgres #{actual_major}, but Flick expects Postgres #{expected_major}.

        Another server is probably answering on the configured port. Start the \
        project's own database with `docker compose up -d`, which listens on \
        port 5418, and check that POSTGRES_PORT is unset or points at it.
        """
    end
  end
end
