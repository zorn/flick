defmodule FlickWeb.LiveViewPipes do
  @moduledoc """
  A collection of functions to help express pipes when processing live view responses.
  """

  alias Phoenix.LiveView.Socket

  @spec ok(Socket.t()) :: {:ok, Socket.t()}
  def ok(%Socket{} = socket), do: {:ok, socket}

  @spec noreply(Socket.t()) :: {:noreply, Socket.t()}
  def noreply(%Socket{} = socket), do: {:noreply, socket}
end
