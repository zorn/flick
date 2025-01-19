defmodule Flick.DateTimeFormatterTest do
  @moduledoc """
  Validates logic of the `Flick.DateTimeFormatter` module.
  """

  use ExUnit.Case, async: true

  doctest Flick.DateTimeFormatter

  import TinyMaps
  import ParameterizedTest
  import ParameterizedTest.Sigil

  alias Flick.DateTimeFormatter

  describe "display_string/2" do
    param_test "generates expected values",
               ~PARAMS"""
               | date_time                | time_zone             | expected                      |
               | ------------------------ | --------------------- | ----------------------------- |
               | ~U[2022-01-02 13:35:15Z] | "UTC"                 | "January 2, 2022 1:35 PM UTC" |
               | ~U[2022-01-02 13:35:15Z] | "America/New_York"    | "January 2, 2022 8:35 AM EST" |
               | ~U[2022-07-11 13:35:15Z] | "America/New_York"    | "July 11, 2022 9:35 AM EDT"   |
               | ~U[2022-01-02 13:35:15Z] | "America/Los_Angeles" | "January 2, 2022 5:35 AM PST" |
               | ~U[2022-01-02 13:35:15Z] | nil                   | "January 2, 2022 1:35 PM UTC" |
               """,
               ~M{date_time, time_zone, expected} do
      if time_zone do
        assert expected == DateTimeFormatter.display_string(date_time, time_zone)
      else
        assert expected == DateTimeFormatter.display_string(date_time)
      end
    end
  end
end
