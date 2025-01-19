defmodule Flick.DateTimeFormatter do
  @moduledoc """
  Provides functions for formatting `DateTime` values into strings appropriate
  for display to the user.
  """

  @doc """
  Returns a string representation of the given `DateTime` value, displaying this
  value using the optional time zone if provided.

  If no time zone is provided, the time zone defaults to "UTC".

  ## Example

      iex> Flick.DateTimeFormatter.display_string(~U[2022-01-02 13:35:15Z], "America/New_York")
      "January 2, 2022 8:35 AM EST"

      iex> Flick.DateTimeFormatter.display_string(~U[2022-01-02 13:35:15Z])
      "January 2, 2022 1:35 PM UTC"
  """
  @spec display_string(
          date_tile_value :: DateTime.t(),
          time_zone :: String.t()
        ) ::
          String.t() | {:error, :time_zone_not_found | :utc_only_time_zone_database}
  def display_string(date_time_value, time_zone \\ "UTC")

  def display_string(date_time_value, time_zone) do
    case DateTime.shift_zone(date_time_value, time_zone) do
      {:ok, date_time_in_time_zone} ->
        Calendar.strftime(date_time_in_time_zone, "%B %-d, %Y %-I:%M %p %Z")

      {:error, reason} ->
        {:error, reason}
    end
  end
end
