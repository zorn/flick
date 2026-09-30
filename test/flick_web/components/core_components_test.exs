defmodule FlickWeb.CoreComponentsTest do
  @moduledoc """
  Verifies that `FlickWeb.CoreComponents.translate_error/1` renders domain
  errors through the `errors` Gettext catalog.
  """

  use ExUnit.Case, async: true

  import FlickWeb.CoreComponents, only: [translate_error: 1]

  describe "translate_error/1" do
    test "success: pluralizes the answer cap with the English catalog" do
      message = "must have at most %{count} answer(s)"

      assert translate_error({message, count: 1}) == "must have at most 1 answer"
      assert translate_error({message, count: 4}) == "must have at most 4 answers"
    end

    test "success: pluralizes the invalid answers label with the English catalog" do
      message = "invalid answer(s): %{answers}"

      assert translate_error({message, count: 1, answers: "Tacos"}) == "invalid answer: Tacos"

      assert translate_error({message, count: 2, answers: "Tacos, Sushi"}) ==
               "invalid answers: Tacos, Sushi"
    end
  end
end
