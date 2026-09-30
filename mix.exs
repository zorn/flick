defmodule Flick.MixProject do
  use Mix.Project

  def project do
    [
      app: :flick,
      version: "0.1.0",
      elixir: "~> 1.20.1",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # `:boundary` must come before `Mix.compilers()`, so its compile tracer
      # sees every cross-module call.
      compilers: [:boundary, :phoenix_live_view] ++ Mix.compilers(),
      cli: cli(),
      boundary: [default: [check: [aliases: true]]],
      listeners: [Phoenix.CodeReloader],

      # Docs
      name: "Flick",
      source_url: "https://github.com/zorn/flick",
      source_ref: "main",
      docs: [
        main: "readme",
        extras: extras(),
        groups_for_extras: groups_for_extras(),
        groups_for_modules: groups_for_modules(),
        # The module-boundaries guide and decision name these hidden
        # (`@moduledoc false`) modules, so ExDoc must not try to autolink them.
        skip_code_autolink_to: ["Flick.Application", "Storybook"],
        # Keeps the README's image paths working both on GitHub and in the
        # generated HTML.
        assets: %{
          "docs/images" => "docs/images",
          "docs/screenshots" => "docs/screenshots"
        }
      ]
    ]
  end

  # A glob publishes a new decision without an edit here. The file names are not
  # zero-padded. Sorting by the leading number keeps `10-` after `2-`.
  #
  # `docs/research/*.md` stays unpublished because each note is a dated snapshot
  # whose links go stale. Published pages link to one by its GitHub blob URL.
  defp extras do
    decisions =
      "docs/decisions/[0-9]*.md"
      |> Path.wildcard()
      |> Enum.sort_by(&(&1 |> Path.basename() |> Integer.parse() |> elem(0)))
      |> Enum.map(&decision_extra/1)

    ["README.md", "docs/ubiquitous_language.md", "docs/module-boundaries.md"] ++ decisions
  end

  # The sidebar already groups these under Decisions, so the title drops the
  # `Decision:` prefix. The page heading still comes from the file and keeps it.
  defp decision_extra(path) do
    case Regex.run(~r/^# Decision: (.+)$/m, File.read!(path), capture: :all_but_first) do
      [title] -> {path, title: title}
      nil -> path
    end
  end

  defp groups_for_extras do
    [
      Guides: ~r{^docs/[^/]+\.md$},
      Decisions: ~r{docs/decisions/}
    ]
  end

  # A module lands in the first group it matches, so `Storybook` comes before
  # the `FlickWeb` catch-all that would otherwise claim `FlickWeb.Storybook`.
  defp groups_for_modules do
    [
      Storybook: [~r/^Storybook\./, ~r/^FlickWeb\.Storybook/],
      Core: [Flick, ~r/^Flick\./],
      Web: [FlickWeb, ~r/^FlickWeb/]
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

  def cli do
    [
      preferred_envs: [precommit: :test]
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

      # For code logic style and enforcement.
      {:boundary, "~> 0.11.0", runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:jump_credo_checks, "~> 0.5", only: [:dev, :test], runtime: false},
      {:oeditus_credo, "~> 0.11", only: [:dev, :test], runtime: false},
      {:excellent_migrations, "~> 0.1", only: [:dev, :test], runtime: false},

      # To Render Markdown.
      {:mdex, "~> 0.14.0"},

      # To santitize the HTML we expect to see in Markdown content.
      {:html_sanitize_ex, "~> 1.4"},

      # For generating HTML documentation.
      {:ex_doc, "~> 0.40.4", only: :dev, runtime: false, warn_if_outdated: true},

      # For security scans.
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},

      # To check locked dependencies against known security advisories.
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},

      # For UI component documentation.
      {:phoenix_storybook, "~> 1.0"},

      # To help us present `DateTime` values in the user's timezone.
      {:tz, "~> 0.28"},

      # To help with making test scenarios easy to describe and maintain.
      {:parameterized_test, "~> 0.6", only: [:dev, :test]},

      # Unorganized
      {:bandit, "~> 1.2"},
      {:dns_cluster, "~> 0.2"},
      {:ecto_sql, "~> 3.10"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:req, "~> 0.5"},
      {:gettext, "~> 1.0"},
      {
        :heroicons,
        # The `override` setting is needed for `phoenix_storybook`.
        github: "tailwindlabs/heroicons",
        tag: "v2.2.0",
        sparse: "optimized",
        app: false,
        compile: false,
        depth: 1,
        override: true
      },
      {:jason, "~> 1.2"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.9.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix, "~> 1.8"},
      {:lazy_html, ">= 0.1.0", only: :test},
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
      "assets.build": ["compile", "tailwind flick", "esbuild flick"],
      "assets.deploy": [
        "tailwind flick --minify",
        "esbuild flick --minify",
        "tailwind storybook --minify",
        "phx.digest"
      ],
      # Mirrors CI's Mix checks, fastest first.
      precommit: [
        "compile --all-warnings --warnings-as-errors",
        "deps.unlock --check-unused",
        "format",
        "credo --strict",
        "xref graph --label compile-connected --fail-above 0",
        "sobelow --config",
        "deps.audit --ignore-file .deps-audit-ignore",
        # Runs in a subprocess because `compile` drops Hex's tasks from this
        # code path ("task could not be found").
        "cmd mix hex.audit",
        # Runs in a subprocess because ExDoc is a dev-only dependency.
        "cmd sh -c 'MIX_ENV=dev mix docs --warnings-as-errors'",
        # Runs in a subprocess so Dialyzer checks the dev build, as CI does.
        "cmd sh -c 'MIX_ENV=dev mix dialyzer'",
        "test --warnings-as-errors"
      ]
    ]
  end
end
