defmodule Flick.BallotsTest do
  use Flick.DataCase, async: true

  alias Flick.Ballots
  alias Flick.Ballots.Ballot

  describe "create_ballot/1" do
    test "success: creates a ballot with questions" do
      attrs = %{
        "questions" => %{
          "0" => %{"_persistent_id" => "0", "title" => "What is your favorite color?"},
          "1" => %{"_persistent_id" => "1", "title" => "What is your favorite food?"}
        },
        "questions_drop" => [""],
        "questions_sort" => ["0", "1"],
        "title" => "My first ballot"
      }

      {:ok, ballot} = Ballots.create_ballot(attrs)

      assert %Ballot{
               title: "My first ballot",
               questions: [
                 %{title: "What is your favorite color?"},
                 %{title: "What is your favorite food?"}
               ]
             } = ballot
    end
  end

  test "failure: title is required" do
    empty_values = ["", nil, " "]

    for empty_value <- empty_values do
      assert {:error, changeset} = Ballots.create_ballot(%{"title" => empty_value})
      assert "can't be blank" in errors_on(changeset).title
    end
  end

  describe "list_ballots/1" do
    test "success: lists ballots" do
      ballot_a = ballot_fixture()
      ballot_b = ballot_fixture()

      assert ballots = Ballots.list_ballots()

      assert length(ballots) == 2
      assert Enum.find(ballots, &match?(^ballot_a, &1))
      assert Enum.find(ballots, &match?(^ballot_b, &1))
    end
  end

  describe "get_ballot!/1" do
    test "success: returns a ballot" do
      %Ballot{id: id, title: title} = ballot_fixture()
      assert %Ballot{id: ^id, title: ^title} = Ballots.get_ballot!(id)
    end

    test "failure: raises when the ballot does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Ballots.get_ballot!(Ecto.UUID.generate())
      end
    end
  end

  describe "fetch_ballot/1" do
    test "success: returns a ballot" do
      %Ballot{id: id, title: title} = ballot_fixture()
      assert {:ok, %Ballot{id: ^id, title: ^title}} = Ballots.fetch_ballot(id)
    end

    test "failure: returns `:not_found` when the ballot does not exist" do
      assert :not_found = Ballots.fetch_ballot(Ecto.UUID.generate())
    end
  end
end
