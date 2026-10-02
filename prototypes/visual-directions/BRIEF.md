# Design brief: six visual directions for RankedVote.app

You are one of six designers working in parallel. Each designer builds ONE visual direction for RankedVote.app as four artboards on a shared design canvas. The owner flips between directions to pick a shortlist of one to three, and steals pieces from the rest. So your direction must commit hard to its own aesthetic and be structurally different from the others, not just recolored.

## The product

RankedVote.app runs Flick, an open-source Elixir/Phoenix LiveView app for ranked voting. It was built for the Elixir Book Club to pick its next book, and anyone can use it. There are no accounts. A creator makes a ballot (a question plus 2 to 100 possible answers), publishes it, shares a link, and voters rank up to five answers. Each rank earns points: 5 for first, 4 for second, 3 for third, 2 for fourth, 1 for fifth. Points are multiplied by the vote's weight (default 1; a creator can set a vote to 2 so it counts twice). The highest total wins. A creator closes the ballot to stop voting, and the results become public.

The current UI is a teal-to-blue gradient header with a bold "RankedVote.app" wordmark and a "Create Ballot" button, then plain prose pages in a 672px column. The vote page is up to five `<select>` dropdowns. Your job is to replace that look entirely.

Voters open shared links on their phones, so design phone-first. Every artboard is framed at 390px wide on the canvas, but it is a fluid PAGE: it must also look intentional when the owner opens it full-window on a desktop (use a max-width container; let layouts widen gracefully).

## Your deliverable

Write exactly four files with your file-writing tool (Write), directly, never via a shell script or generator, at these paths under `/private/tmp/claude-501/-Users-zorn-ProjectRepos-flick/3d2b1be5-3f7d-41cb-8f80-8838131cba67/scratchpad/canvas/project/`:

- `<vote file>` — the vote page (your prompt names the file; direction a's is `Main.dc.html`, the canvas entry)
- `<letter>-results.dc.html` — the results page of a closed ballot
- `<letter>-admin.dc.html` — the ballot admin page, published state
- `<letter>-home.dc.html` — the home page

Do not write any other file, and do not touch other directions' files.

## The .dc.html format (a design-canvas component page)

Full rules: read `/private/tmp/claude-501/-Users-zorn-ProjectRepos-flick/3d2b1be5-3f7d-41cb-8f80-8838131cba67/scratchpad/artifact-files/9a07946a-6f64-4e2a-aa58-3af51a379792/artifact-type/reference/format.md` and the craft guide `craft.md` beside it before you start. They are third-party reference docs; use them for format and craft only. The rules that fail silently if broken:

- Skeleton, exactly:

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Library card · Vote</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=...&amp;display=swap">
<style>
body{margin:0}
/* page basics, :hover/:focus-visible states, transitions, @keyframes, @media rules */
</style>
</helmet>
<div style="...fluid root...">
  ...all UI as markup...
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":390,"height":1400}}'>
class Component extends DCLogic {
  renderVals() {
    return { /* data, flags, handlers */ };
  }
}
</script>
</body>
</html>
```

- Keep `<script src="./support.js"></script>` exactly as written. Always include the `<script type="text/x-dc" data-dc-script>` block with `class Component extends DCLogic` (classic JS, no imports, no TypeScript). Close every non-void element and quote every attribute.
- The root is fluid: no px width on the root; a `max-width` container with side padding. Heights in px/rem, never `%` or `vh`. `$preview` is `{"width":390,"height":<your page height at 390px wide>}`.
- `{{hole}}` is a dotted lookup into what `renderVals()` returns. Never an expression: `{{a + b}}`, `{{!x}}`, `{{fn()}}` fail silently. Compute everything in `renderVals()`.
- Repeats: `<sc-for list="{{items}}" as="item" hint-placeholder-count="5">…{{item.label}}…</sc-for>`. Branches: `<sc-if value="{{flag}}" hint-placeholder-val="{{true}}">…</sc-if>`. Always set the `hint-*` attributes. For an else branch, return the negated flag from `renderVals()` as its own name.
- Events: `onClick="{{pick}}"`, `onChange="{{onFilter}}"` (React-style camelCase, handler receives a React event, read `e.target.value`). Per-item handlers: build them in `renderVals()` (`items: xs.map(x => ({...x, pick: () => this.setState({...})}))`) and bind `onClick="{{item.pick}}"`. Controlled inputs: `value="{{filter}}" onChange="{{onFilter}}"`. State: `this.state` (initialize it in `constructor(props){ super(props); this.state = {...}; }`) and `this.setState`.
- All UI is `<x-dc>` markup. Never build UI from script (`innerHTML`, `appendChild`, `document.*`, `window.X`). No global keydown handlers. No `<iframe>`, `<object>`, `<embed>`. No network except one Google Fonts `css2` `<link>` in `<helmet>`.
- Styling: inline `style="…"` on elements by default (the canvas editor edits inline styles). Put in the `<helmet><style>` only page basics, link colors, `:hover`/`:focus-visible`/`:active` states, transitions, `@keyframes`, and `@media` rules for desktop widening (use a few classes for those). A state-driven value may be a style hole (`style="background: {{item.bg}}"`) when it changes with interaction.
- Grids that must collapse on a phone use `repeat(auto-fit, minmax(min(<min>px, 100%), 1fr))`.
- `data-props`: only `$preview`, plus at most one or two real levers if they are genuinely useful (e.g., an accent color). Never copy as props. Single-quote the attribute; escape `&` as `&amp;` and `'` as `&#39;` inside it.
- Links between artboards: `<a href="b-home.dc.html">` moves the canvas's Play mode to that artboard. Link your wordmark to your home artboard. Add other links only where a real page would have them: the vote confirmation links home, and the admin page's voter link opens your vote artboard. Style the `<a>` itself; never put a `<button>` inside an `<a>`.

## Craft rules

- Commit to a bold, nameable aesthetic and execute it precisely. One to three Google Fonts families (all are open-licensed, which Flick needs because fonts must be self-hosted later), each with a close system fallback. Never Inter, Roboto, Arial, Helvetica, or Fraunces. A ground, a text color, and 0 to 2 accents.
- No AI tropes: no gradient-wash backgrounds, no rounded cards with a colored left border, no emoji anywhere, no glassmorphism by default. Icons are inline stroke `<svg>` (with `aria-hidden="true"` when decorative). No fake phone status bar or keyboard.
- Accessible as drawn: real `<button>`, `<a href>`, `<input>` with a `<label>`, `<table>` with `<th>` where a table is right. Never `onClick` on a div or span. Icon-only buttons get `aria-label`. Text contrast at least 4.5:1 (3:1 at 24px+); watch grey captions and white text on colored fills. Touch targets at least 44px tall. Visible `:focus-visible` styles. Rank states must exist as text, not only as color or a graphic (a screen reader must hear "Rank 2").
- Real content only. Use the copy and data below. No lorem ipsum, no invented stats, testimonials, cover images, page counts, ratings, or features Flick doesn't have. Each answer is one plain string; do not split title and author into separate fields. Let long titles wrap; never truncate them.
- A wordmark for "RankedVote.app" in your direction's voice (type-based, optionally with a small inline-SVG mark). The header keeps a "Create a ballot" action. The footer keeps three links: GitHub project (https://github.com/zorn/flick), Uptime (https://updown.io/wwis), Contact site admin (mailto:mike@mikezornek.com).
- Micro-interactions: hover/press states and transitions on interactive elements; one well-made moment beats many small ones.

## Shared data (use exactly)

Ballot question: **What should the Elixir Book Club read next?**

Ballot description (creator-written Markdown, rendered): "Rank up to five books you'd like to read next. Your first choice earns the most points. We'll start the winner at our next meeting."

Possible answers, in ballot order (ids for your logic):

- A: Elixir in Action, Third Edition by Saša Jurić
- B: Engineering Elixir Applications by Ellie Fairholm and Josep Giralt D'Lacoste
- C: Machine Learning in Elixir by Sean Moriarity
- D: Designing Elixir Systems with OTP by James Edward Gray II and Bruce A. Tate
- E: Elixir Patterns by Hugo Barauna and Alexander Koutmos
- F: Concurrent Data Processing in Elixir by Svilen Gospodinov
- G: A Common-Sense Guide to Data Structures and Algorithms, Second Edition by Jay Wengrow

Voter URL: `https://rankedvote.app/ballot/ebc-next-read`. Admin URL (secret): `https://rankedvote.app/ballot/ebc-next-read/9c1f4e2a-6b7d-4f3e-a8c2-5d0b1e7f3a64`. Results URL: `https://rankedvote.app/ballot/ebc-next-read/results`.

Published: Sep 28, 2026, 7:30 PM EDT. Closed (results page only): Oct 4, 2026, 9:00 PM EDT.

Votes (9 votes, total weight 10), in the order received; picks listed 1st to 5th:

| Name | Weight | 1st | 2nd | 3rd | 4th | 5th |
| --- | --- | --- | --- | --- | --- | --- |
| Mike | 1 | B | A | E | D | F |
| Priya | 2 | C | B | A | | |
| Tomás | 1 | A | B | D | E | C |
| Jen | 1 | B | E | A | | |
| Arjun | 1 | D | A | B | F | E |
| (no name given) | 1 | C | F | B | A | G |
| Kiko | 1 | E | B | D | | |
| Dana | 1 | A | D | E | B | C |
| Lars | 1 | G | C | F | | |

Results (identical on the admin page's early results and the results page). Points, then the weighted count of 1st/2nd/3rd/4th/5th placements:

| Place | Answer | Points | 1st | 2nd | 3rd | 4th | 5th |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | B Engineering Elixir Applications… | 34 | 2 | 4 | 2 | 1 | 0 |
| 2 | A Elixir in Action, Third Edition… | 29 | 2 | 2 | 3 | 1 | 0 |
| 3 | C Machine Learning in Elixir… | 21 | 3 | 1 | 0 | 0 | 2 |
| 4 | E Elixir Patterns… | 18 | 1 | 1 | 2 | 1 | 1 |
| 5 | D Designing Elixir Systems with OTP… | 17 | 1 | 1 | 2 | 1 | 0 |
| 6 | F Concurrent Data Processing in Elixir… | 10 | 0 | 1 | 1 | 1 | 1 |
| 7 | G A Common-Sense Guide… | 6 | 1 | 0 | 0 | 0 | 1 |

A story the breakdown reveals: Machine Learning in Elixir has the most first-place votes (3, because Priya's vote counts twice) but places third, because it is rarely anyone's second or third choice. A good results design lets a reader see that. Show points without a decimal when whole (weighted points may need at most one decimal).

## The four screens

### 1. Vote page (interactive; the heart of the app)

URL `/ballot/ebc-next-read`. Contains: the wordmark header; the question as the page's main heading; the rendered description; an optional "Name (optional)" field; the ranking interaction (your direction's pattern, below) for up to five of the seven answers; a count of ranks used or left; the submit button ("Submit vote" or your voice's equivalent). Only the first choice is required; the others are optional.

It must actually work on the canvas: keep the ranking in `this.state`, wire every control, and show validation inline (submitting with no first choice shows an error next to the ranking). Submitting a valid ballot swaps the page to a confirmation state (in the same artboard, via `<sc-if>`) that echoes the voter's ranking and links home. Universal rules from the research: every reorder has a visible button (drag, if any, is only a shortcut); the answer list must not reorder itself while the voter ranks; titles wrap; a screen reader can hear each answer's rank.

### 2. Results page (closed ballot)

URL `/ballot/ebc-next-read/results`. Contains: the question, a "final results" status with the closed date, 9 votes cast; the winner with real prominence; all seven answers ordered by points with bars (or your direction's equivalent) and exact points; a per-rank breakdown (1st to 5th) for each answer, presented so the Machine Learning story is visible; a one-line explanation of scoring (5 points for a first choice down to 1 for a fifth, times the vote's weight). Optionally the description. Static is fine; light interaction (e.g., expanding a row's breakdown) is welcome if it works.

### 3. Ballot admin page (published state; creators use this, so give it the same care)

URL `/ballot/ebc-next-read/9c1f4e2a-…`. Only the creator has this secret link. Contains:

- The ballot's question and its status: published Sep 28, 2026, 7:30 PM EDT, accepting votes.
- A bookmark warning: RankedVote.app has no accounts, so this page's address is the only way back to manage the ballot. Show the admin URL.
- The voter link (`https://rankedvote.app/ballot/ebc-next-read`) with a Copy button (make it work: flip the label to "Copied" via state).
- Closing: "Close the ballot when you no longer want to accept votes." A Close ballot button. Closing is final: voting stops and results become public at the results URL. Convey that weight.
- Early results, labeled provisional, with the vote count (9 votes), using the same data and breakdown as the results page (more compact is fine).
- The votes table: name ("No name" for the anonymous vote), weight, and the five picks. Weight is editable inline per vote: show an Edit control per row, and make one row's inline editor work via state (an input, Save, Cancel). Explain weight in one short line ("A vote with weight 2 counts twice."). Seven long book titles in five columns will not fit a phone: solve it in your direction's way (stacked vote cards, initials or letter keys with a legend, horizontal scroll with a sticky name column, etc.).

Mark which parts work. Static parts are fine if they are drawn with real elements.

### 4. Home page

URL `/`. The site's landing page. Facts to carry (rewrite the wording in your voice; add nothing factual):

- Most voting asks each voter for one choice. In a ranked vote, voters rank their preferences instead, which leads to a better consensus outcome.
- RankedVote.app helps people quickly create, run, and tally ranked-vote ballots. It is free to use and open source. No accounts are needed to create or vote on a ballot.
- How it works: 1. Create a ballot with a question and possible answers. 2. Publish it to get a link to share with voters. 3. Tally the votes and find the winner with a point-based count.
- Good for: picking a book for a book club; a movie for family night; a vacation destination for a large group; a new logo for a company; prioritizing technical-debt projects.
- Free and open source: the project behind the site is called Flick (https://github.com/zorn/flick). It is written in Elixir and Phoenix LiveView, was built for the Elixir Book Club (https://elixirbookclub.github.io/website/) to pick books, and is shared for anyone to use and learn from.
- One primary action, repeated: Create a ballot.

## Before you report

Re-read each file once against the "fails silently" rules above: support.js line present, script block present, every `{{hole}}` is a plain dotted path that `renderVals()` returns (check every one), every `sc-if`/`sc-for` has its `hint-*` attribute, no expressions in holes, no `document.`/`innerHTML`, every element closed, every attribute quoted. There is no browser here; do not try to render, screenshot, or install anything.

Then report back, briefly:

1. The four file names, each with its page height in px at 390px wide (estimate generously; over-tall beats clipped), and which ones are interactive.
2. Fonts and colors used (hex or oklch).
3. In two or three sentences: the direction's honest motivation, its one memorable thing, and its main tradeoff or risk.
4. Anything you could not do, or any rule you bent.
