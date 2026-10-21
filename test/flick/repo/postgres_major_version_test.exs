defmodule Flick.Repo.PostgresMajorVersionTest do
  # Each file pins the Postgres major on its own, and YAML cannot read Elixir
  # config. This keeps them from drifting apart on a version change.
  use ExUnit.Case, async: true

  @pins [
    {"compose.yml", ~r/image: postgres:(\d+)/},
    {".github/workflows/build-and-test.yaml", ~r/image: postgres:(\d+)/},
    {"render.yaml", ~r/postgresMajorVersion: "(\d+)"/}
  ]

  # It reads config files rather than calling application code.
  # credo:disable-for-next-line Jump.CredoChecks.VacuousTest
  test "every pinned Postgres major matches :postgres_major_version" do
    expected = Application.fetch_env!(:flick, :postgres_major_version)

    for {file, pattern} <- @pins do
      assert [_, major] = Regex.run(pattern, File.read!(file)), "#{file} has no Postgres pin"

      assert String.to_integer(major) == expected,
             "#{file} pins Postgres #{major}, but :postgres_major_version is #{expected}"
    end
  end
end
