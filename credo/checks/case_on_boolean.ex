defmodule Flick.Credo.Check.CaseOnBoolean do
  @moduledoc """
  Flags a `case` whose only clauses are `true` and `false`.

  Vendored from LocalCents for #233. It is an independent reimplementation of the idea behind
  `ExSlop.Check.Refactor.CaseTrueFalse` (MIT, © 2026 Danila Poyarkov). Flick
  vendors this one rule rather than take on the whole `ex_slop` collection.
  """

  use Credo.Check,
    id: "FLK002",
    base_priority: :normal,
    category: :refactor,
    explanations: [
      check: """
      A `case` whose only clauses are `true` and `false` reads better as
      `if`/`else`. With `if`, the reader doesn't scan two clauses to find the
      truthy branch. This is a common shape in machine-written Elixir.

          # bad
          case connected?(socket) do
            true -> :live
            false -> :static
          end

          # good
          if connected?(socket), do: :live, else: :static
      """
    ]

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:case, meta, [_subject, [do: clauses]]} = ast, issues, issue_meta)
       when is_list(clauses) do
    if boolean_clauses?(clauses) do
      {ast, [issue_for(issue_meta, meta[:line]) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  # A guard or a catch-all makes a genuine `case`, not a disguised `if`.
  defp boolean_clauses?([_, _] = clauses) do
    patterns = clauses |> Enum.map(&clause_pattern/1) |> Enum.sort()
    patterns == [false, true]
  end

  defp boolean_clauses?(_), do: false

  defp clause_pattern({:->, _meta, [[pattern], _body]}) when pattern in [true, false], do: pattern
  defp clause_pattern(_), do: nil

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "`case` on a boolean (`true`/`false` clauses) reads better as `if`/`else`.",
      trigger: "case",
      line_no: line_no
    )
  end
end
