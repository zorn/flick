defmodule Flick.RankedVoting.EmbedParams do
  @moduledoc """
  Bounds user-provided params for `embeds_many` fields before they are cast.

  `cast_embed` builds one child changeset per entry before any count check
  runs. Without a bound, an anonymous client can make the server build any
  number of them.
  """

  @doc """
  Keeps at most `limit + 1` entries of the list or map param under `key`.

  One entry past the limit is enough for the schema's count check to reject
  the params.
  """
  @spec cap(map(), String.t(), pos_integer()) :: map()
  def cap(attrs, key, limit) do
    case attrs do
      %{^key => value} when is_list(value) ->
        %{attrs | key => Enum.take(value, limit + 1)}

      %{^key => value} when is_map(value) ->
        %{attrs | key => value |> Enum.take(limit + 1) |> Map.new()}

      _ ->
        attrs
    end
  end
end
