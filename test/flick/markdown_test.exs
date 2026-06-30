defmodule Flick.MarkdownTest do
  @moduledoc """
  Validates logic of the `Flick.RankedVoting` module.
  """

  use ExUnit.Case, async: true

  describe "render_to_html/1" do
    test "renders Markdown content to HTML" do
      markdown = """
      # Hello, world!

      This is a test of the [Markdown](https://en.wikipedia.org/wiki/Markdown) rendering system.
      """

      expected_html =
        """
        <h1>Hello, world!</h1>
        <p>This is a test of the <a href=\"https://en.wikipedia.org/wiki/Markdown\">Markdown</a> rendering system.</p>
        """
        |> String.trim()

      assert expected_html == Flick.Markdown.render_to_html(markdown)
    end

    test "does not crash when handed an empty string" do
      assert "" == Flick.Markdown.render_to_html("")
    end

    test "uses SmartyPants style for quotes" do
      markdown = """
      "Hello, world!" she said. It's cool.
      """

      expected_html =
        """
        <p>“Hello, world!” she said. It’s cool.</p>
        """
        |> String.trim()

      assert expected_html == Flick.Markdown.render_to_html(markdown)
    end

    test "basic display html tags in the Markdown content are allowed" do
      markdown = """
      Hello<br />world!

      This is a <strong>test</strong>.
      """

      expected_html =
        """
        <p>Hello<br />world!</p>
        <p>This is a <strong>test</strong>.</p>
        """
        |> String.trim()

      assert expected_html == Flick.Markdown.render_to_html(markdown)
    end

    test "script tags are removed" do
      markdown = """
      <script>alert('Hello, world!')</script>
      """

      expected_html =
        """
        alert('Hello, world!')
        """
        |> String.trim()

      assert expected_html == Flick.Markdown.render_to_html(markdown)
    end

    test "anchor tags in Markdown content are allowed" do
      markdown = """
      A <a href="https://en.wikipedia.org/wiki/Markdown">link</a> to the Markdown Wikipedia page.
      """

      expected_html =
        """
        <p>A <a href="https://en.wikipedia.org/wiki/Markdown">link</a> to the Markdown Wikipedia page.</p>
        """
        |> String.trim()

      assert expected_html == Flick.Markdown.render_to_html(markdown)
    end
  end
end
