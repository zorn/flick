defmodule Storybook do
  @moduledoc false

  # phoenix_storybook compiles the files under `storybook/` into `Storybook.*`
  # modules. They are dev-only scaffolding, not domain code, so this boundary
  # claims them and turns off its checks.
  use Boundary, check: [in: false, out: false]
end
