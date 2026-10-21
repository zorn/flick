defmodule Flick.AgentGuidesTest do
  # Agents read a guide under `docs/agents/` only when the index in
  # `AGENTS.md` points to it, so an unlinked guide is silently ignored.
  use ExUnit.Case, async: true

  @index "AGENTS.md"
  @guides Path.wildcard("docs/agents/*.md")

  test "the index links to every guide" do
    linked = @index |> local_links() |> MapSet.new()

    for guide <- @guides do
      assert guide in linked, "#{@index} has no index entry for #{guide}"
    end
  end

  test "every local link in the index and the guides resolves to a file" do
    for file <- [@index | @guides], target <- local_links(file) do
      assert File.regular?(target), "#{file} links to #{target}, which does not exist"
    end
  end

  # Returns each relative Markdown link target in `file`, resolved from the
  # file's own directory and with any `#anchor` removed.
  defp local_links(file) do
    ~r/\]\(([^)\s]+)\)/
    |> Regex.scan(File.read!(file), capture: :all_but_first)
    |> Enum.map(fn [target] -> target |> String.split("#") |> hd() end)
    |> Enum.reject(&(&1 == "" or String.contains?(&1, "://")))
    |> Enum.map(&Path.relative_to_cwd(Path.expand(&1, Path.dirname(file))))
  end
end
