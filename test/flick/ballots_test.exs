defmodule Flick.BallotsTest do
  use Flick.DataCase

  alias Flick.Ballots
  alias Flick.Ballots.Ballot

  describe "create_ballot/1" do
    test "creates a ballot with questions" do
      {:ok, ballot} = Ballots.create_ballot("My first ballot")

      assert %Ballot{} = ballot
      assert ballot.title == "My first ballot"
      assert Enum.count(ballot.questions) == 2
    end
  end
end
