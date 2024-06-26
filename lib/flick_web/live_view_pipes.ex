defmodule FlickWeb.LiveViewPipes do
  @moduledoc """
  A collection of functions to help express pipes when processing live view responses.
  """

  @spec ok(Socket.t()) :: {:ok, Socket.t()}
  def ok(socket), do: {:ok, socket}
end
