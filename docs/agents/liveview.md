# LiveView and HEEx

## Layout and core components

- Begin every LiveView template with `<Layouts.app flash={@flash} ...>`, which wraps all inner content and renders flash messages. `<.flash_group>` belongs to `layouts.ex` alone.
- Render icons with `<.icon name="hero-x-mark" class="w-5 h-5" />`.
- Build form inputs with `<.input>` from `core_components.ex`. A `class` you pass replaces the default classes rather than adding to them, so your classes must fully style the input.

## HEEx

- Interpolate values with `{...}`, both in attributes and in tag bodies. Use `<%= ... %>` only for block constructs (`if`, `cond`, `case`, `for`) in tag bodies:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

- Write a class attribute with several values as a list, and wrap an inline `if` in parentheses:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100")
      ]}>Text</a>

- Generate repeated content with `:for` or `<%= for item <- @collection do %>`.
- Branch three or more ways with `cond` or `case`. Elixir has no `else if`.
- Write template comments as `<%!-- comment --%>`.
- To show literal `{` or `}`, such as a code snippet, add `phx-no-curly-interpolation` to the parent tag. Inside it, `<%= ... %>` still interpolates.
- Give key elements, such as forms and buttons, a unique DOM `id`. Tests select elements by these IDs.

## LiveViews

- Name a LiveView with a `Live` suffix, under a namespace that matches its domain, such as `FlickWeb.Ballots.IndexLive` or `FlickWeb.Vote.ResultsLive`.
- Navigate with `<.link navigate={href}>` and `<.link patch={href}>` in templates, and with `push_navigate/2` and `push_patch/2` in LiveViews.
- Build UI from function components. Reach for a LiveComponent only when part of a page needs its own state and event handling.

## Streams

Flick assigns its collections as plain lists today, because each list is small. Use a stream when a collection can grow without bound. A stream works like this:

- The parent element needs `phx-update="stream"` and a DOM `id`. Each child takes its `id` from the stream:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- Add items with `stream/4` (`at: -1` prepends), and remove them with `stream_delete/3`.
- A stream is not enumerable. To filter or refresh it, refetch the data and call `stream(socket, :messages, messages, reset: true)`.
- A stream keeps no count. Track a count or an empty flag in a separate assign. An empty state can also be a sibling `<div class="hidden only:block">`, when it is the only other child.
- When an assign changes what a streamed item shows, re-insert that item with `stream_insert/3`.

## JavaScript hooks

- Write a hook that lives with its template as a colocated hook. Its name starts with a `.`:

      <input type="text" id="user-phone-number" phx-hook=".PhoneNumber" />
      <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
        export default {
          mounted() { ... }
        }
      </script>

- Put a shared hook in `assets/js/hooks/` and register it in `assets/js/app.js`, as `SortableInputsFor` is.
- When a hook manages its own DOM, also set `phx-update="ignore"` on its element.
- `push_event/3` returns a new socket. Return it, or rebind it, so the event is sent.

## Forms

- Build every form from `to_form/2`, assigned in the LiveView, and render it with `<.simple_form for={@form} id="...">` from `core_components.ex`, which wraps `<.form>`. Read fields as `@form[:field]`. The changeset stays in the LiveView.
- From a changeset, `to_form/1` takes the data, params, and errors, and names the params after the schema. A `Ballot` form submits `%{"ballot" => ballot_params}`.
- From `handle_event` params, `to_form/2` expects string keys. Pass `as: :user` to nest them under a name.
- Nest a form with `<.inputs_for>`.
