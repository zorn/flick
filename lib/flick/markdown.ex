defmodule Flick.Markdown do
  @moduledoc """
  Provides functions for securely and consistently rendering Markdown content.
  """

  @doc """
  Renders the provided Markdown content string to HTML.

  This function does escape some HTML tags that are seen as a security threat,
  but should allow basic HTML display tags seen in the Markdown content to
  persist the transformation.
  """
  @spec render_to_html(String.t()) :: String.t()
  def render_to_html(markdown_content) when is_binary(markdown_content) do
    opts = [
      parse: [smart: true],
      render: [unsafe: true]
    ]

    html_doc = MDEx.to_html!(markdown_content, opts)

    HtmlSanitizeEx.markdown_html(html_doc)
  end
end
