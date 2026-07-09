defmodule Flick.Credo.Check.RawInHeexTest do
  use Credo.Test.Case, async: true

  alias Flick.Credo.Check.RawInHeex

  test "reports a `raw/1` call inside a HEEx template" do
    """
    defmodule FlickWeb.SampleLive do
      def render(assigns) do
        ~H\"\"\"
        <div>
          {raw(@description)}
        </div>
        \"\"\"
      end
    end
    """
    |> to_source_file()
    |> run_check(RawInHeex)
    |> assert_issue(fn issue ->
      assert issue.trigger == "raw"
      assert issue.line_no == 5
    end)
  end

  test "reports each un-opted-out `raw/1` call when several are present" do
    """
    defmodule FlickWeb.SampleLive do
      def render(assigns) do
        ~H\"\"\"
        <div>{raw(@a)}</div>
        <div>{raw(@b)}</div>
        \"\"\"
      end
    end
    """
    |> to_source_file()
    |> run_check(RawInHeex)
    |> assert_issues(2)
  end

  test "does not report templates without `raw/1`" do
    """
    defmodule FlickWeb.SampleLive do
      def render(assigns) do
        ~H\"\"\"
        <div>{@description}</div>
        \"\"\"
      end
    end
    """
    |> to_source_file()
    |> run_check(RawInHeex)
    |> refute_issues()
  end

  test "does not report a `raw/1` call opted out via a same-line marker" do
    """
    defmodule FlickWeb.SampleLive do
      def render(assigns) do
        ~H\"\"\"
        <div>{raw(@description)}</div><%!-- credo:allow-raw sanitized --%>
        \"\"\"
      end
    end
    """
    |> to_source_file()
    |> run_check(RawInHeex)
    |> refute_issues()
  end

  test "does not report a `raw/1` call opted out via a marker on the preceding line" do
    """
    defmodule FlickWeb.SampleLive do
      def render(assigns) do
        ~H\"\"\"
        <div>
          <%!-- credo:allow-raw sanitized --%>
          {raw(@description)}
        </div>
        \"\"\"
      end
    end
    """
    |> to_source_file()
    |> run_check(RawInHeex)
    |> refute_issues()
  end

  test "does not report the substring `raw` inside another identifier" do
    """
    defmodule FlickWeb.SampleLive do
      def render(assigns) do
        ~H\"\"\"
        <div>{draw(@shape)}</div>
        \"\"\"
      end
    end
    """
    |> to_source_file()
    |> run_check(RawInHeex)
    |> refute_issues()
  end

  test "does not look inside non-HEEx sigils" do
    """
    defmodule Flick.Sample do
      def doc do
        ~s\"\"\"
        This mentions raw(@description) as prose, not a template.
        \"\"\"
      end
    end
    """
    |> to_source_file()
    |> run_check(RawInHeex)
    |> refute_issues()
  end
end
