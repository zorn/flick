defmodule Storybook do
  @moduledoc false

  # phoenix_storybook compiles `storybook/` into `Storybook.*` modules. They are
  # dev scaffolding, not domain code.
  use Boundary, check: [in: false, out: false]
end
