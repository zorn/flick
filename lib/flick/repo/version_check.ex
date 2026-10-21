defmodule Flick.Repo.VersionCheck do
  @moduledoc """
  Refuses to boot when `Flick.Repo` reaches a Postgres server on a major
  version other than `:postgres_major_version`.

  Dev and test connect to whatever server answers on the configured port.
  Without this check, they can run unnoticed on an older Postgres than
  production. Prod sets no expected version, so the check does nothing there.

  It runs as a child after `Flick.Repo`, so a mismatch stops the application
  before the endpoint starts. On a match, its start function returns `:ignore`,
  and no process stays running.
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
      verify!(server_version_num!(), expected_major)
    end

    :ignore
  end

  defp server_version_num! do
    %{rows: [[server_version_num]]} =
      Flick.Repo.query!("SHOW server_version_num", [], log: false)

    server_version_num
  rescue
    # Postgrex already logs why each connection failed, so the pool's own
    # message would only bury the hint.
    DBConnection.ConnectionError ->
      reraise """
              Flick.Repo could not reach Postgres on port #{port()}.

              Start the database with `docker compose up -d`. Create it with `mix ecto.setup`.
              """,
              __STACKTRACE__
  end

  @doc """
  Returns `:ok` when `server_version_num` has the major version
  `expected_major`. Raises otherwise.
  """
  @spec verify!(String.t(), pos_integer()) :: :ok
  def verify!(server_version_num, expected_major) do
    case div(String.to_integer(server_version_num), 10_000) do
      ^expected_major ->
        :ok

      actual_major ->
        raise """
        Flick.Repo reached Postgres #{actual_major}, but Flick expects Postgres #{expected_major}.

        Another server is probably answering on port #{port()}. Start the \
        project's own database with `docker compose up -d`. Check that \
        POSTGRES_PORT matches the port it publishes.
        """
    end
  end

  defp port, do: Flick.Repo.config()[:port]
end
