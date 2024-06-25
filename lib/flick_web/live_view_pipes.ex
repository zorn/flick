defmodule FlickWeb.LiveViewPipes do
  @moduledoc """
  A collection of functions to help express pipes when processing live view responses.
  """

  alias Phoenix.LiveView.Socket

  @spec ok(Socket.t()) :: {:ok, Socket.t()}
  def ok(socket), do: {:ok, socket}
end
