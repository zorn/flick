# Testing

## Test data and processes

- Set up ballots with the fixtures in `test/support/fixtures/ballot_fixture.ex`: `ballot_fixture/1` for a draft, `published_ballot_fixture/1`, and `closed_ballot_fixture/1`.
- Start processes with `start_supervised!/1`, which cleans them up between tests.
- Synchronize on messages, not time. To wait for a process to finish, monitor it and assert on its `DOWN` message:

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

  To make sure a process has handled earlier messages, call `_ = :sys.get_state(pid)`.
- To debug a failure, run one file with `mix test test/my_test.exs`, or rerun only the failures with `mix test --failed`.

## LiveView tests

- Drive LiveViews with `Phoenix.LiveViewTest`: `render_change/2` and `render_submit/2` for forms, `element/2` and `has_element?/2` for assertions.
- Select elements by the DOM IDs in the template, such as `has_element?(view, "#ballot-form")`. Assert on the presence of elements rather than on raw HTML or text, which change more often.
- To see the HTML behind a failing selector, filter it with `LazyHTML` so the output stays short:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")
