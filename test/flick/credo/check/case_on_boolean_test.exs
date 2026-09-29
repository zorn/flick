defmodule Flick.Credo.Check.CaseOnBooleanTest do
  use Credo.Test.Case, async: true

  alias Flick.Credo.Check.CaseOnBoolean

  test "reports a `case` whose only clauses are `true` and `false`" do
    """
    defmodule Flick.Sample do
      def mode(connected?) do
        case connected? do
          true -> :live
          false -> :static
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseOnBoolean)
    |> assert_issue(fn issue ->
      assert issue.trigger == "case"
      assert issue.line_no == 3
    end)
  end

  test "reports the clauses in either order" do
    """
    defmodule Flick.Sample do
      def mode(connected?) do
        case connected? do
          false -> :static
          true -> :live
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseOnBoolean)
    |> assert_issue()
  end

  test "does not report a guarded `true` clause" do
    """
    defmodule Flick.Sample do
      def mode(connected?, count) do
        case connected? do
          true when count > 0 -> :live
          false -> :static
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseOnBoolean)
    |> refute_issues()
  end

  test "does not report a `case` with a catch-all clause" do
    """
    defmodule Flick.Sample do
      def mode(value) do
        case value do
          true -> :live
          false -> :static
          _ -> :unknown
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseOnBoolean)
    |> refute_issues()
  end

  test "does not report a `case` on non-boolean patterns" do
    """
    defmodule Flick.Sample do
      def label(status) do
        case status do
          :draft -> "Draft"
          :published -> "Published"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseOnBoolean)
    |> refute_issues()
  end
end
