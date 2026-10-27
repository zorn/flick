defmodule FlickWeb.PromExTest do
  # Sets RENDER_GIT_COMMIT for the whole VM, so it can't run alongside other tests.
  use ExUnit.Case, async: false

  alias FlickWeb.PromEx

  test "git_sha/0 returns the commit Render sets" do
    previous = System.get_env("RENDER_GIT_COMMIT")

    on_exit(fn ->
      if previous,
        do: System.put_env("RENDER_GIT_COMMIT", previous),
        else: System.delete_env("RENDER_GIT_COMMIT")
    end)

    System.put_env("RENDER_GIT_COMMIT", "d6cb6195a4e0c1f3b2a9e8d7c6b5a4f3e2d1c0b9")

    assert PromEx.git_sha() == "d6cb6195a4e0c1f3b2a9e8d7c6b5a4f3e2d1c0b9"
  end
end
