# Our custom Credo checks live in `credo/checks/` (outside `lib/`, since they
# depend on `Credo.Check`, which is unavailable in `:prod`). Credo loads them
# via the `requires` option in `.credo.exs`; here we load them so their unit
# tests can reference the modules.
Code.require_file("credo/checks/raw_in_heex.ex")

# Credo is `runtime: false`, so its supervision tree (which our custom-check
# tests rely on via `Credo.Test.Case`) is not started automatically. When
# `mix precommit` runs the `credo` task before `test`, the supervisor is
# already up, so only start it when needed.
unless Process.whereis(Credo.Supervisor) do
  {:ok, _} = Application.ensure_all_started(:credo)
end

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Flick.Repo, :manual)
