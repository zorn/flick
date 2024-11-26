defmodule Flick.MixProject do
  use Mix.Project

  def project do
    [
      app: :flick,
      version: "0.1.0",
      elixir: "~> 1.17.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Flick.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # For test-driven development.
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},

      # To allow our test descriptions to use a condensed map syntax.
      {:tiny_maps, "~> 3.0"},

      # For generating seed and test data.
      {:faker, "~> 0.18", only: [:dev, :test]},

      # For code logic style and enforcement.
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # For Observability.
      {:appsignal_phoenix, "~> 2.5"},

      # To Render Markdown.
      {:earmark, "~> 1.4"},

      # For security scans.
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},

      # For UI component documentation.
      {:phoenix_storybook, "~> 0.7.0"},

      # Unorganized
      {:bandit, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:ecto_sql, "~> 3.10"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:finch, "~> 0.13"},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.20"},
      {
        :heroicons,
        # The `override` setting is needed for `phoenix_storybook`.
        github: "tailwindlabs/heroicons",
        tag: "v2.1.1",
        sparse: "optimized",
        app: false,
        compile: false,
        depth: 1,
        override: true
      },
      {:jason, "~> 1.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      {:phoenix, "~> 1.7.11"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.5"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind flick", "esbuild flick"],
      "assets.deploy": [
        "tailwind flick --minify",
        "esbuild flick --minify",
        "tailwind storybook --minify",
        "phx.digest"
      ]
    ]
  end
end
