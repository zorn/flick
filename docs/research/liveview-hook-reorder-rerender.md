# Forcing a LiveView patch after a hook reorders the DOM

Researched 2026-09-28 against phoenix_live_view 1.2.12 (the version in `mix.lock`). Local source paths are under `deps/phoenix_live_view/`.

## Answer

1. **A render counter is a known community workaround, not a documented or core-team pattern.** No LiveView doc, changelog entry, or core-team post recommends a nonce assign to force a diff. The nearest first-party endorsement is Chris McCord's advice to put data attributes on a hook's container so that `updated` can read server state ([issue #388](https://github.com/phoenixframework/phoenix_live_view/issues/388)). Community forum answers do suggest toggling an assign to force a re-render ([Elixir Forum, 2021](https://elixirforum.com/t/how-to-force-liveview-to-re-render-a-page/37180)).
2. **In Flick, the counter's premise does not hold.** A swap of two blank rows does not render identically. `<.inputs_for>` gives every row a `_persistent_id` that travels with the row when Ecto sorts it, and the answer input's DOM id is built from that persistent id. After a swap, the hidden `_persistent_id` values and the input ids change places, so the server sends a diff. A probe test confirmed this (see "Verification" below).
3. **Recommendation: drop the counter after a quick browser check, and pin the real mechanism with a test.** Chris McCord added the persistent id to support reordering inside `inputs_for`, so the diff is a framework guarantee, not an accident. If the browser check shows a stale row, keep the counter. It is cheap and harmless; only its comment and test need to change.

## Why an empty diff skips everything

The server does not send a diff when the render is unchanged. `push_diff/3` sends a no-op reply when the diff is `%{}` (`lib/phoenix_live_view/channel.ex:1099`). Since v1.1, comprehensions track changes per entry, so only changed entries are sent ([v1.1 changelog](https://github.com/phoenixframework/phoenix_live_view/blob/v1.1.0/CHANGELOG.md#change-tracking-in-comprehensions); [assigns guide](https://github.com/phoenixframework/phoenix_live_view/blob/v1.2.12/guides/server/assigns-eex.md#comprehensions)).

The client patches only when the diff is not empty (`assets/js/phoenix_live_view/view.ts:996`). When it does patch, it renders the whole LiveView container from its cached tree and morphs it against the live DOM (`view.ts:996-1001`). That full morph is what repairs rows the hook moved: any non-empty diff fixes stale ids, `data-index`, and `disabled` everywhere in the container.

A hook's `updated` runs only if the patch reaches its element and the element's subtree differs from the new render (`fromEl.isEqualNode(toEl)` in `view.ts:651-663`, then `view.ts:743-747`). The docs define `updated` as "the element has been updated in the DOM by the server" ([JS interop guide](https://phoenix-live-view.hexdocs.pm/1.2.12/js-interop.html#client-hooks-via-phx-hook)).

Every patch-time escape hatch (`onBeforeElUpdated`, `JS.ignore_attributes`, `beforeUpdate`) runs inside a patch. None of them can create a patch when the diff is empty.

## Why Flick's swap is never an empty diff

`inputs_for` adds a hidden `_persistent_id` input per row and uses it for the row form's `id` (`lib/phoenix_component.ex:2823-2895`). `<.input field={answer_form[:value]}>` therefore renders `id="ballot_possible_answers_<persistent id>_value"`. The input's `name` stays index-based (`ballot[possible_answers][0][value]`).

When the hook swaps two rows, the browser still sends each row's `_persistent_id` by its index name, and the sort param reorders the children. The first rendered row now carries persistent id `1`, so both its hidden input value and its text input id differ from the previous render.

Steffen Deusch describes the purpose: the persistent id "ensures that even when forms are re-ordered, the fields retain their original ID and therefore morphdom does not recreate them" ([issue #3673](https://github.com/phoenixframework/phoenix_live_view/issues/3673)). Chris McCord added it in [PR #2570](https://github.com/phoenixframework/phoenix_live_view/pull/2570) ("Support ordering within inputs_for", v0.19.0). It can be turned off with `skip_persistent_id` (`lib/phoenix_component.ex:2804`, [PR #3677](https://github.com/phoenixframework/phoenix_live_view/pull/3677)). Flick must not set that option if it relies on this behavior.

### Verification

A throwaway LiveViewTest (not committed) loaded `/ballot/new`, sent `possible_answers_sort: ["1", "0"]` through `form("#ballot-form") |> render_change/2` twice, and compared `#possible-answer-rows` with `data-change` stripped. The render differed from the initial render after the first swap and differed again after the swap back. `form/2` includes the form's hidden `_persistent_id` inputs, as the browser does.

Not verified: behavior in a real browser. The recommendation depends on a one-minute manual check (remove the counter, swap two blank rows with the buttons, and confirm the ids, `disabled` states, and focus are right).

## First-party examples

The LiveView 1.2.12 docs contain no SortableJS example. The `inputs_for` docs show `sort_param` and `drop_param` with add and remove buttons only (`lib/phoenix_component.ex:2593-2670`).

Chris McCord's 0.19 release post points to drag and drop built on nested streams ([Phoenix blog, 2023-05-29](https://www.phoenixframework.org/blog/phoenix-liveview-0.19-released)). His demo app, [Todo Trek](https://github.com/chrismccord/todo_trek/blob/328da395b820cd3072f806a36374cf882b854967/assets/js/app.js#L58-L73), has a `SortableInputsFor` hook that matches Flick's design. SortableJS moves the row in the DOM, and the hook dispatches an `input` event so the form's `phx-change` sends the new sort order. It has no counter, no `phx-update="ignore"`, and no `updated` callback.

The Phoenix Files drag-and-drop post uses `pushEventTo` with stable row ids and leaves the server handler empty ([Fly.io, 2023](https://fly.io/phoenix-files/liveview-drag-and-drop/)). It does not address the DOM falling out of sync.

## Alternatives and their cost for Flick

1. **`phx-update="ignore"` plus `pushEvent`.** Rejected: the server could no longer patch values, errors, or `disabled` inside the list. Since v0.20.4, an ignored element takes only its data attributes from the server ([changelog](https://github.com/phoenixframework/phoenix_live_view/blob/v1.0.17/CHANGELOG.md#0204-2024-02-01)), and its hook's `updated` runs only when those data attributes change ([JS interop guide](https://phoenix-live-view.hexdocs.pm/1.2.12/js-interop.html#client-hooks-via-phx-hook)). This is the one place where a data-attribute nonce is the documented tool.
2. **Streams.** High cost. Todo Trek streams one form per item, which does not fit one ballot form with `sort_param` and `drop_param`. An existing stream item keeps its position on `stream_insert`, so moving one needs `stream_delete` then `stream_insert ... at:` (`lib/phoenix_live_view.ex:2155-2168`). Index-based ids and `disabled` states would need every row re-inserted on each move.
3. **Stable DOM ids on each row (`id={answer_form.id}`).** Low cost and optional. Morphdom keys nodes by `id` (`assets/js/phoenix_live_view/dom_patch.ts:208-224`), so rows would move as whole units instead of being patched by position. It does not make a diff happen by itself; the persistent id already does that. It could simplify focus handling if the move buttons also took persistent-id-based ids.
4. **Revert the DOM move in the hook, then push the new order.** Medium cost. The server owns the order, and a no-op render then matches the untouched DOM, so nothing goes stale. It needs a custom event that reorders the params, instead of the DOM-order `sort_param` flow; a forum answer takes this route for button reordering ([Elixir Forum, 2025](https://elixirforum.com/t/reordering-nested-form-inputs-with-buttons-not-drag-and-drop/61669), community, not core team). Not worth it while the persistent id guarantees a diff.
5. **`JS.ignore_attributes`.** Does not fit. It stops the server from patching the named attributes (`lib/phoenix_live_view/js.ex:1052-1077`), and Flick needs the server to patch `data-index`, ids, and `disabled`.
6. **`dom: onBeforeElUpdated`.** Does not fit. It is a global callback that runs during a patch to preserve client-side attributes ([JS interop guide](https://phoenix-live-view.hexdocs.pm/1.2.12/js-interop.html)). It cannot trigger a patch.
7. **Render counter (current code).** Works and costs little: one attribute in each diff, and a `beforeUpdate` and `updated` call on every change event, where `updated` returns early without a pending focus target. Its drawback in Flick is that its comment and test (`test/flick_web/live/ballots/editor_live_test.exs:78`) state that blank rows render identically after a swap, which is false.

## Recommendation for Flick

Remove `:change_count` and `data-change` from `lib/flick_web/live/ballots/editor_live.ex` (lines 19, 90, 170-175) after the browser check passes. Replace the counter test with one that swaps two blank rows and asserts that the answer input ids trade places (for example, that `#ballot_possible_answers_1_value` now has the name `ballot[possible_answers][0][value]`). That test pins the behavior the hook depends on and fails loudly if someone adds `skip_persistent_id`.

If the browser check fails, keep the counter and rewrite its comment to say it guarantees a patch on every change event. The pattern is sound; only its stated reason is wrong.
