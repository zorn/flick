defmodule Flick.DateTimeFormatterTest do
  @moduledoc """
  Validates logic of the `Flick.DateTimeFormatter` module.
  """

  alias Flick.DateTimeFormatter

  use ExUnit.Case, async: true

  describe "display_string/2" do
    test "" do
      date_time_value = ~U[2022-01-02 13:35:15Z]
      time_zone = "America/New_York"

      assert "January 2, 2022 8:35 AM EST" ==
               DateTimeFormatter.display_string(date_time_value, time_zone)
    end
  end
end
