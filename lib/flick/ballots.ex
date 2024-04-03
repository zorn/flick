defmodule Flick.Ballots do
  alias Flick.Ballots.Ballot
  alias Flick.Repo

  # Flick.Ballots.create_ballot("My first ballot")
  def create_ballot(title) do
    attrs = %{
      title: title,
      questions: [
        %{title: "What is your favorite color?"},
        %{title: "What is your favorite food?"}
      ]
    }

    %Ballot{}
    |> Ballot.changeset(attrs)
    |> Repo.insert()
  end
end
