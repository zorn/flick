defmodule Flick.Repo.GrafanaReaderRoleTest do
  # SET LOCAL ROLE lasts only until the sandbox rolls back the test's
  # transaction, so these tests share nothing. A denied query aborts that
  # transaction, so each test expects at most one denial.
  use Flick.DataCase, async: true

  setup do
    Repo.query!("SET LOCAL ROLE flick_grafana_reader")
    :ok
  end

  test "reads the columns the business dashboard counts" do
    assert %{rows: [[_ballots]]} = Repo.query!("SELECT count(published_at) FROM ballots")
    assert %{rows: [[_votes]]} = Repo.query!("SELECT count(ballot_id) FROM votes")
  end

  test "cannot read a ballot's secret" do
    assert_insufficient_privilege("SELECT secret FROM ballots")
  end

  test "cannot read a ballot's title" do
    assert_insufficient_privilege("SELECT question_title FROM ballots")
  end

  test "cannot read a voter's name" do
    assert_insufficient_privilege("SELECT full_name FROM votes")
  end

  test "cannot write" do
    assert_insufficient_privilege("DELETE FROM votes")
  end

  defp assert_insufficient_privilege(sql) do
    assert_raise Postgrex.Error, ~r/permission denied/, fn -> Repo.query!(sql) end
  end
end
