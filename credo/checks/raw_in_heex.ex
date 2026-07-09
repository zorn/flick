defmodule Flick.Credo.Check.RawInHeex do
  use Credo.Check,
    id: "FLK001",
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Phoenix's `raw/1` marks its argument as already-safe, unescaped HTML.
      Inside a HEEx (`~H`) template this bypasses LiveView's automatic
      HTML-escaping, which is the primary defense against cross-site scripting
      (XSS).

      Neither Sobelow nor Credo's default checks look inside the contents of
      `~H` sigils, so `raw/1` calls in templates are otherwise invisible to our
      security tooling (see issue #131). This check closes that gap by scanning
      the template source of every `~H` sigil for `raw/1` calls.

      When you have deliberately produced safe HTML (for example, by rendering
      Markdown through `Flick.Markdown.render_to_html/1`, which sanitizes its
      output with `HtmlSanitizeEx`), you can opt out on a case-by-case basis by
      placing a `credo:allow-raw` marker in a HEEx comment on the same line as,
      or the line above, the `raw/1` call:

          <%!-- credo:allow-raw sanitized by Flick.Markdown --%>
          {@ballot.description && raw(Flick.Markdown.render_to_html(@ballot.description))}

      Opting out is a conscious decision to own the security implications of
      that specific `raw/1` call.
      """
    ]

  @allow_marker "credo:allow-raw"

  # A real `raw/1` call runs inside a HEEx interpolation, opened by either `{`
  # (attribute/body interpolation) or `<%= ` (body/block interpolation). We
  # require such an opener before `raw(` on the same line so that the literal
  # text `raw(` in prose, HTML attributes, or `<pre>` code samples is not
  # flagged. `[^{}]*` keeps the opener and the call within the same expression.
  @raw_call ~r/(?:\{|<%=)[^{}]*\braw\s*\(/

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # A HEEx template compiles to a `~H` sigil whose contents are a (dedented)
  # binary in the AST. `raw/1` calls live inside that binary, so we scan its
  # text rather than the surrounding Elixir AST.
  defp traverse({:sigil_H, meta, [{:<<>>, _, parts}, _modifiers]} = ast, issues, issue_meta) do
    template = parts |> Enum.filter(&is_binary/1) |> Enum.join()
    {ast, issues ++ raw_issues(template, meta[:line], issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp raw_issues(template, sigil_line, issue_meta) do
    lines = String.split(template, "\n")

    lines
    |> Enum.with_index()
    |> Enum.filter(fn {line, index} ->
      Regex.match?(@raw_call, line) and not allowed?(lines, index)
    end)
    |> Enum.map(fn {_line, index} ->
      # The first line of the sigil's contents is the line after the `~H"""`
      # opener, so the source line is `sigil_line + 1 + index`.
      issue_for(issue_meta, sigil_line + 1 + index)
    end)
  end

  defp allowed?(lines, index) do
    current = Enum.at(lines, index, "")
    previous = if index > 0, do: Enum.at(lines, index - 1, ""), else: ""
    String.contains?(current, @allow_marker) or String.contains?(previous, @allow_marker)
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message:
        "Avoid `raw/1` in HEEx templates; it bypasses HTML escaping and risks XSS. " <>
          "Sanitize the content and add a `credo:allow-raw` marker to opt out.",
      trigger: "raw",
      line_no: line_no
    )
  end
end
