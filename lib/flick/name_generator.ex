defmodule Flick.NameGenerator do
  @moduledoc "Provides functions to generate random person names for use in seeds and test data."

  @first_names ~w(Alice Bob Carol David Emma Frank Grace Henry Isabel James Karen Leo Maria Nora Oscar Paula Quinn Rachel Sam Tara)
  @last_names ~w(Anderson Brown Clark Davis Evans Foster Garcia Harris Irving Johnson Kelly Lopez Martinez Nelson Owen Parker Quinn Rivera Scott Taylor)

  @spec person_name() :: String.t()
  def person_name do
    "#{Enum.random(@first_names)} #{Enum.random(@last_names)}"
  end
end
