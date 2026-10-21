defmodule Flick.Repo.VersionCheckTest do
  @moduledoc """
  Validates that `Flick.Repo.VersionCheck` rejects a Postgres server whose
  major version differs from the expected one.
  """

  use ExUnit.Case, async: true

  alias Flick.Repo.VersionCheck

  describe "verify!/2" do
    test "accepts a server on the expected major version" do
      assert VersionCheck.verify!("180006", 18) == :ok
    end

    test "raises when the server runs another major version" do
      error = assert_raise RuntimeError, fn -> VersionCheck.verify!("140017", 18) end

      assert error.message =~ "Postgres 14"
      assert error.message =~ "Postgres 18"
      assert error.message =~ "docker compose up -d"
    end
  end
end
