# Round 2 brief: refine the Soft and tactile direction

Round 1 explored six visual directions for RankedVote.app. The owner chose **e. Soft and tactile** and wants a round of refinement before moving on. You are one of four designers working in parallel on round 2. Each of you builds a few artboards on the same design canvas, so the shared system below matters: the boards must read as one product.

## Read first

1. The round-1 brief, which still governs the product facts, the shared ballot data (answers A to G, the nine votes, the results table), the `.dc.html` format rules, and the craft rules: `/private/tmp/claude-501/-Users-zorn-ProjectRepos-flick/3d2b1be5-3f7d-41cb-8f80-8838131cba67/scratchpad/brief.md`. Read it fully, along with the format reference and craft guide it links.
2. The round-1 Soft and tactile files you are refining, in `/private/tmp/claude-501/-Users-zorn-ProjectRepos-flick/3d2b1be5-3f7d-41cb-8f80-8838131cba67/scratchpad/canvas/project/`: `e-vote.dc.html`, `e-results.dc.html`, `e-admin.dc.html`, `e-home.dc.html`. Read the ones your assignment names. Reuse what works: the fonts (Bricolage Grotesque and Figtree), the oat ground, the tactile press, the stacked-ovals mark in the wordmark (the owner likes it), and the overall warmth. Do not edit these files.

## The owner's feedback on round 1

- **Vote page flow.** The two-column desktop layout (ranking on the left, choices on the right) is busy. The copy "tap a choice below" is wrong when the choices are not below. The owner wants two passes: first the voter taps answers to pick and unpick them; then a final "your ranking" area at the end is the last chance to adjust the order, enter the optional name, and submit.
- **Rank numerals.** Round 1 used white numerals on ranks 1 and 2 and dark numerals on ranks 3 to 5. The numeral color must be the same for all five.
- **Long titles.** Selecting an answer added a remove button that changed how a long title wraps. Selection must never change an answer's wrapping.
- **Name field.** It says "optional" but not why we ask. The real reason: a ballot's admin can give some votes more weight (the Elixir Book Club counts regulars' votes more), and the name is how the admin knows whose vote is whose.
- **Buttons.** The header's "Create a ballot" was a full pill while other buttons were rounded rectangles with assorted radii. Use one consistent shape.
- **Footer.** Keep GitHub project, Uptime, and Contact site admin, but as quiet secondary text links, never button-styled.
- **Contrast.** The owner is uneasy about dark text on the tan ground. It measures about 14:1, so the issue is perceptual (warmth, muddiness, texture noise behind text), not a WCAG failure. Keep the tan.
- **Texture.** The owner likes the tan but wants to try textures beyond the dot grid.
- **Dark mode.** Explore a dark variant.
- **Results page.** Simplify the scoring explainer card and the per-rank breakdown (the "2, 4, 2, 1, 0" rows). Drop the "Most 1st-choice votes" callout entirely; do not highlight that story at all.
- **Ballot admin.** The vote cards with letter keys (A, D, and a key to decode them) read as noisy. Rethink them, including a version with a plain table like today's production page. Move "Close the ballot" to the top, beside the published status, instead of a separate section at the bottom.
- **Home page.** "Rank your favorites" must sit on one line (no wrap at 390px); "decide together" can follow on the next line. Replace the "a new logo for your company" use case, because answers are text only. Replace the final "your group's next big decision / Create a ballot" card with a simple action below the use-case section. The purple "Built for a book club, shared with everyone" section has awkward spacing and empty space on the right; rework its layout.

## Shared round-2 system (every board uses it)

**Theme through CSS custom properties.** Define the palette once in `<helmet><style>` on your root class, and reference it from inline styles as `var(--…)`. A `.r2-dark` class on the root swaps the values. Every board declares a `dark` boolean tweak in `data-props` (`"dark":{"editor":"boolean","default":false}`) and sets the root's class from it in `renderVals()`, so any board can flip to dark. Use these names and values:

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `--ground` | `#F7EFE3` | `#17131F` | page background (oat / deep plum-charcoal) |
| `--texture` | `#E6DBCA` | `#2A2337` | dot texture color |
| `--surface` | `#FFFDF8` | `#221C2D` | cards |
| `--well` | `#F1E9DC` | `#1D1827` | recessed areas, empty slots |
| `--line` | `#E3D7C4` | `#3A3148` | borders, hairlines |
| `--ink` | `#1E1730` | `#F3EDE4` | primary text |
| `--ink-2` | `#4A4358` | `#C8BFD3` | secondary text |
| `--action` | `#FF9F61` | `#FF9F61` | primary buttons (with `--on-action` text) |
| `--action-edge` | `#C96736` | `#B85A2C` | pressed-edge shadow under primary buttons |
| `--on-action` | `#1E1730` | `#1E1730` | text on primary buttons |
| `--link` | `#462F80` | `#C4B2FF` | links, focus rings |
| `--danger` | `#A92227` | `#FF8A8A` | errors, close-ballot emphasis |

Verify any pair you add with a contrast check (4.5:1 for text, 3:1 for large text and UI shapes). Shadows in dark mode should be darker and tighter, never light glows.

**Rank numerals.** All five rank chips use **white numerals** on deep fills: 1st `#3B2A78`, 2nd `#8A2E6E`, 3rd `#A8432A`, 4th `#7A5300`, 5th `#2C6A5C` (each 6:1 or better against white). In dark mode, give chips a 2px `--surface`-contrasting ring so they hold their shape. Never rely on telling these hues apart: a chip always shows its number, and charts label segments or avoid color-coding by rank. (The style-sheet board explores alternatives; use this default everywhere else.)

**Buttons.** One shape for every button, header "Create a ballot" included: corner radius 14px, the tactile press from round 1, 44px minimum height. Primary buttons use `--action`; secondary buttons use `--surface` with a `--line` border. Reserve full pills for status tags only; rank chips are circles.

**Footer.** One quiet line or small group of text links in `--ink-2` at 14 to 15px, separated by middots, underlined on hover. No backgrounds, borders, or button shapes.

**Texture.** Keep round 1's dot grid on your boards (the style-sheet board explores alternatives). Keep texture out from behind body text: text sits on `--surface` cards or on a calm, untextured band where it helps.

**Layout.** The owner reviews full-window on a desktop, and voters use phones. Every board is a fluid PAGE framed at 390px wide, and it must look deliberate at 1280px: a centered column (about 640 to 760px max for the vote and results flows, wider is fine for admin tables) rather than side-by-side panes. Never write directional copy ("below", "on the right") that breaks when the layout reflows; say "Choose", "Your ranking", and so on.

**Long titles.** Reserve the same space for controls in every state, so selecting or ranking an answer never changes where its title wraps. For example, a fixed-width trailing slot that holds a "+" or an empty ring when unpicked and the rank chip when picked, with remove handled by tapping the card again or by a control on its own row.

**No callouts** about which answer had the most first-choice votes, anywhere.

## Your artboards

File names start with `r2-`. Write only your files, with Write (or Edit for fixes), into `.../scratchpad/canvas/project/`. Your prompt names your files.

## Report back

1. Each file, its page height in px at 390px wide (estimate generously), and whether it is interactive.
2. Per board, two or three sentences on what changed from round 1 and why, so the owner can review against the feedback.
3. Any rule you bent or anything you could not do.
