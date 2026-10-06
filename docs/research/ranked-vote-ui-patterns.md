# How ranked-vote tools let voters rank and show results

Researched 2026-10-02 for [issue #253](https://github.com/zorn/flick/issues/253). The sources are each tool's own help pages and live ballots, the Center for Civic Design (CCD) ranked-choice ballot research, W3C WAI documents, and library docs. Where a help center was thin or blocked automated reads, the file cites the tool's live ballot pages instead. This file says *answer* for the thing a voter ranks, which other tools call a candidate, choice, item, or option. RankedVote.co, cited below, is a separate product from RankedVote.app.

Flick's limits frame every finding. A ballot has 2 to 100 answers of any length. A voter ranks up to five. Each rank earns points, 5 for first down to 1 for fifth, multiplied by the vote's weight.

## Answer

1. **Build the vote page on "tap in order" or "pick, then order", not on a dropdown per rank or a dragged full list.** In both patterns, the voter taps an answer to give it the next open rank. They hold up at 100 answers, and they cannot produce a gap or a duplicate. CCD's accessible ranked-choice ballot uses tap in order, and its participants "had no problems understanding this interaction." OpaVote and Slido use pick, then order.
2. **Retire the five dropdowns.** CCD's ballot guidelines say "Do not use drop-down lists to number rankings," and GOV.UK's research lists five ways users struggle with selects. In Flick, each select repeats up to 100 answers, and a voter can leave a gap that still scores.
3. **Keep drag as a shortcut inside the five ranked slots, never as the only way to rank.** WCAG 2.5.7 requires a non-dragging way to do anything that dragging does. RankedVote.co says a dragged full list gets tedious past 12 answers, with 5 to 7 visible on a phone. SortableJS, which the editor uses, has no keyboard or screen-reader support. Visible move-up, move-down, and remove buttons are the primary path.
4. **Use the rank grid only in the Official ballot direction, and test it at 100 answers.** NYC's grid ranks up to five, exactly like Flick, so it reads as a real ballot. CCD found that a grid "quickly becomes overwhelming and frustrating" with many candidates. On a phone, five oval columns leave less than half the width for a long title.
5. **Show results as an ordered list with a bar and the exact points for each answer, winner first, with a per-rank breakdown.** Points-count tools sort answers by score, and SurveyMonkey and Pigeonhole Live chart them as bars. A breakdown (how many 1st through 5th ranks each answer got) shows how a total was earned, as Award Force's Borda table does. Skip round-by-round tables and Sankey charts. They explain instant runoff, which Flick does not use.
6. **Keep early results on the ballot admin page, label them provisional, and show the vote count.** OpaVote, Slido, StrawPoll, and Pigeonhole Live all make live results an organizer setting. Weighted points can be fractional, and CCD notes that whole numbers are easier to read, so show at most one decimal.
7. **Do not reorder the answer list while the voter ranks.** CCD found that automatic reordering disorients voters and makes them trust the ballot less. Leave answers in ballot order, mark each with its rank, and show the ranked order in a separate summary or behind a "Put in order" control.

Anything not called out above stands as recommended.

## Ranking patterns

| Pattern | How the voter ranks | Tools | On a phone | At 100 answers |
| --- | --- | --- | --- | --- |
| Dropdown per rank | Picks an answer from a select for each rank | Flick today, Mentimeter | Native picker; long titles cut off | Each select lists all 100 |
| Number per answer | Gives answers a rank number, by select or by typing | ElectionBuddy, Typeform, Qualtrics | One small control per row | 100 controls; duplicates and gaps possible |
| Full-list drag | Drags answers into order | RankedVote.co, StrawPoll, SurveyMonkey, Qualtrics | 5 to 7 rows visible | Unworkable; orders all 100 |
| Pick, then order | Adds answers to a separate ranked list, then reorders it | OpaVote, Slido, W3C APG example | Short list stays in view | Scales, with a filter |
| Tap in order | Taps answers in rank order; each shows its rank in place | CCD accessible ballot, Pigeonhole Live | One tap per rank | Scales, with a filter |
| Rank grid | Fills one oval per rank column | NYC, Maine, and Alaska paper ballots; RankedVote.co; Qualtrics; Google Forms | Five columns squeeze the title | 100 rows by 5 columns |
| Pairwise comparison | Picks the better of two answers, many times | All Our Ideas | Easy per step | 4,950 pairs |
| Text notation | Types `A>B=D>C` | Condorcet.vote | Impractical | Impractical |

### Dropdown per rank

Flick's vote page renders five selects, labeled "First Preference" to "Fifth Preference (Optional)" (`lib/flick_web/live/vote/vote_capture_live.ex`). Mentimeter starts the same way: "the participant starts by selecting items in the select menus," and "Rearranging them afterward is easily done through up and down arrows" ([Mentimeter](https://help.mentimeter.com/how-to-vote/rating-items-or-allocating-points)).

CCD's ballot guidelines say "Do not use drop-down lists to number rankings" ([CCD 2017, p. 67](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=67)). GOV.UK's research found that users "tried to type into the select," "confused focused items with selected items," and had "not understood that they can scroll down to see more items" ([GOV.UK Design System](https://design-system.service.gov.uk/components/select/)).

Flick adds two problems of its own. Each select repeats the full list of up to 100 answers. A voter can also fill the first and third selects and skip the second. Flick accepts that vote and gives the third-slot answer 3 points, because `points_for_answer_in_votes/2` scores by slot position (`lib/flick/ranked_voting.ex`).

### Number per answer

ElectionBuddy's sample preferential ballot puts a rank select (blank, 1, 2, 3) beside each candidate ([ElectionBuddy sample ballot](https://electionbuddy.com/process/ballot-samples/executive-elections/)). Typeform respondents "drag the options, or select numbers from the dropdown list" ([Typeform](https://help.typeform.com/hc/en-us/articles/360052767651-Ranking-question)). In Qualtrics' Text Box format, respondents "type in their preferred ranking" ([Qualtrics](https://www.qualtrics.com/support/survey-platform/survey-module/editing-questions/question-types-guide/standard-content/rank-order/)).

This is the digital form of a hand-ranked paper ballot. CCD's participants "strongly preferred it over the grid-style ballot," but they "often made initial mistakes" ([CCD 2017, p. 52](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=52)), and they "had difficulty ranking long contests" ([CCD 2022, p. 10](https://civicdesign.org/wp-content/uploads/2022/10/CCD-RCV-Best-Practices-Ballot-Design-2022-1.pdf#page=10)). At 100 answers, the voter scans 100 controls to set five, and the page must catch duplicate and skipped numbers.

### Full-list drag

RankedVote.co's Drag and Drop ballot shows answers "in a single column and voters drag their most preferred to the top." It "is optimized for online use on mobile devices" ([RankedVote.co](https://www.rankedvote.co/guides/using-rankedvote/choose-ballot-types)). The same guide warns that "once you start getting into the 12+ choice range, voters need to scroll," and that "5-7 choices will appear on the screen at a time." A vote on that ballot "ranks *all* choices."

StrawPoll's ranking poll tells voters to "Drag your preferred option to the top" ([StrawPoll poll](https://strawpoll.com/YVyPmJaXBnN)). SurveyMonkey's ranking question uses drag and drop, and its help advises: "Try to limit the number of ranking choices to about 5" ([SurveyMonkey](https://help.surveymonkey.com/en/surveymonkey/create/ranking-question/)). Qualtrics calls its drag format "appropriate for shorter lists" ([Qualtrics](https://www.qualtrics.com/support/survey-platform/survey-module/editing-questions/question-types-guide/standard-content/rank-order/)).

For Flick, a full-list drag fails twice. Moving the 100th answer to the top takes a long drag through a scrolling list. The order of answers 6 to 100 also means nothing, because only five ranks earn points.

### Pick, then order

OpaVote's demo ballot says "Use the buttons to add choices to the ballot, and then drag to arrange them in order of preference" ([OpaVote demo](https://opavote.com/vote/5654402576678912)). A choice list with Add and Remove buttons sits beside a numbered "Your ballot" list. In Slido, "participants select their options and can then drag/drop them in their preferred order" ([Slido](https://community.slido.com/live-polls-quizzes-and-surveys-55/run-a-ranking-poll-727)). The W3C's rearrangeable listbox example has two lists, "Important Features" and "Unimportant Features," with Up, Down, and Not Important buttons ([W3C APG](https://www.w3.org/WAI/ARIA/apg/patterns/listbox/examples/listbox-rearrangeable/)).

CCD calls this the "two list" digital style. Its first test of the style went badly because of "weak visual design and interaction cues," but "Participants liked the clean interface and the ability to choose how many to rank" ([CCD 2017, p. 54](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=54)).

This pattern fits Flick's shape. The long list needs one action per answer (add), and ordering happens in a list of at most five.

### Tap in order

In CCD's accessible ranked-choice ballot, "Voters find and select their 1st choice candidate, then find and select their 2nd choice candidate, and so on until they are done ranking." "Participants had no problems understanding this interaction" ([CCD 2024, p. 8](https://civicdesign.org/wp-content/uploads/2024/09/CCD-RCV-Best-Practices-Accessible-Ballot-Design-2024.pdf#page=8)). The list stays still: "When a candidate is selected, rank number changes but candidate order doesn't, so voters don't lose where they are in the candidate list" ([CCD 2022, p. 11](https://civicdesign.org/wp-content/uploads/2022/10/CCD-RCV-Best-Practices-Ballot-Design-2022-1.pdf#page=11)). A "Put in Order" button sorts the list by rank when the voter asks ([CCD 2024, p. 10](https://civicdesign.org/wp-content/uploads/2024/09/CCD-RCV-Best-Practices-Accessible-Ballot-Design-2024.pdf#page=10)).

Pigeonhole Live offers both gestures: attendees "can either drag them into order or tap them in the order of their preference (1st, 2nd, 3rd, etc.)" ([Pigeonhole Live](https://help.pigeonholelive.com/hc/en-us/articles/58064534705689-Ranking-Polls)).

Tap in order marks ranks in place on the full list. Pick, then order moves picked answers into a separate short list. Both scale to 100 answers if the page adds a filter and keeps a "ranked so far" summary in view. That last point is this research's inference for Flick, not a tested finding.

### Rank grid

Printed ranked-choice ballots in Maine, Alaska, and New York City use a grid. Answers are rows, ranks are columns, and the voter fills one oval per column ([RankedVote.co](https://www.rankedvote.co/guides/using-rankedvote/choose-ballot-types)). NYC voters "rank up to five candidates," under two rules: "Only rank one candidate per column" and "Don't rank any candidate more than once" ([NYC Votes practice ballot](https://www.nycvotes.org/how-to-vote/ranked-choice-voting/practice-ballot/)). CCD treats a grid of "up to 5 ranks" as the common layout and gives tested instruction text: "Rank up to 5 candidates. Mark only one oval in each column." ([CCD 2022, pp. 5 and 22](https://civicdesign.org/wp-content/uploads/2022/10/CCD-RCV-Best-Practices-Ballot-Design-2022-1.pdf#page=5)).

Online, RankedVote.co's Grid ballot defaults to five ranks and warns at once about skipped and duplicate ranks ([RankedVote.co](https://www.rankedvote.co/guides/using-rankedvote/choose-ballot-types)). Survey tools offer the same layout. Qualtrics' Radio Buttons format has respondents "select a rank for each item from columns of possible rankings" ([Qualtrics](https://www.qualtrics.com/support/survey-platform/survey-module/editing-questions/question-types-guide/standard-content/rank-order/)). Google Forms has no ranking question, so the usual workaround is a multiple choice grid with the rule "limit one choice per column" ([Google Forms help](https://support.google.com/docs/answer/7322334)).

The evidence on size disagrees. RankedVote.co recommends its grid for 12 or more answers, compared with its drag ballot. CCD found that a paper grid "with a larger number of candidates ... quickly becomes overwhelming and frustrating" and "takes longer to complete" ([CCD 2017, p. 51](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=51)). On phones, Qualtrics turns its matrix tables into an accordion, because they "often require respondents to scroll to see the full question" ([Qualtrics matrix table](https://www.qualtrics.com/support/survey-platform/survey-module/editing-questions/question-types-guide/standard-content/matrix-table/)). Five ovals at Apple's 44-point minimum use about 220 points of a 375-point-wide phone, which leaves less than half the width for the title.

### Pairwise comparison and text notation

All Our Ideas shows a respondent two items and asks for a pick, or "I can't decide." It scores each item as "the estimated chance that it will beat a randomly chosen item for a randomly chosen respondent" ([Salganik and Levy, 2015](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0123483)). Each step is easy on a phone. But 100 answers make 4,950 pairs, and the output is a score, not a top five, so it cannot feed Flick's 5-to-1 tally.

Condorcet.vote enters votes as text such as `A>B=D>C` ([Condorcet.vote manual](https://www.condorcet.vote/Manual)). That suits bulk entry by an administrator, not a voter on a phone, and the site now says it "is no longer actively maintained."

## Partial ranking

Flick lets a voter rank fewer than five answers, and most tools allow it too. OpaVote makes a full ranking optional through its "Require full vote" setting ([OpaVote help](https://opavote.com/help/online-elections)). Mentimeter's audience "can choose to rank all the items you have provided or just a few of them" ([Mentimeter](https://help.mentimeter.com/en/articles/2780579-ranking-questions)). SurveyMonkey adds an N/A checkbox per row ([SurveyMonkey](https://help.surveymonkey.com/en/surveymonkey/create/ranking-question/)). In Slido, an answer a voter does not rank "automatically receives 0 points," which matches Flick ([Slido staff answer](https://community.slido.com/community-q-a-7/i-need-help-to-understand-ranking-poll-results-3500)). RankedVote.co's drag ballot is the exception: it always ranks every answer.

CCD recommends letting voters leave answers unranked, because "Voters had diverse—and strongly held—opinions about how many candidates to rank" ([CCD 2017, p. 70](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=70)). It also recommends saying how many ranks remain, as in "You may rank # more candidate(s)" ([CCD 2024, p. 13](https://civicdesign.org/wp-content/uploads/2024/09/CCD-RCV-Best-Practices-Accessible-Ballot-Design-2024.pdf#page=13)). Tap in order and pick, then order cannot create a gap. The dropdown, number, and grid patterns can, so they need a gap warning like RankedVote.co's.

## Results displays

### Points tallies

Several tools tally ranks as points, as Flick does:

- **Slido** gives "the option ranked first ... 3 points, the second gets 2 points and the third gets 1 point," then divides by participants for an average score ([Slido staff answer](https://community.slido.com/community-q-a-7/i-need-help-to-understand-ranking-poll-results-3500)).
- **Mentimeter** uses a "borda count." After responses arrive, "the items will rearrange themselves," and "Items that weren't selected will be displayed at the bottom" ([Mentimeter](https://help.mentimeter.com/en/articles/2780579-ranking-questions)).
- **SurveyMonkey** weights ranks 5 down to 1 for five choices. Its "Weighted Average" chart puts the most preferred answer highest, and its "Distribution" chart shows how many respondents picked each answer at each rank ([SurveyMonkey](https://help.surveymonkey.com/en/surveymonkey/create/ranking-question/)).
- **Pigeonhole Live** shows a "Weighted Average Score" as a vertical or horizontal bar chart ([Pigeonhole Live](https://help.pigeonholelive.com/hc/en-us/articles/58064534705689-Ranking-Polls)).
- **Award Force** walks through Flick's exact scheme, "1st preference = 5 points" down to "5th preference = 1 point," as a table with one column per preference and a total. Its users compute it in a spreadsheet, outside the product ([Award Force](https://support.awardforce.com/hc/en-us/articles/360001319415-How-to-calculate-a-ranked-list-when-using-Top-pick)).
- **MeetingPulse** reports each answer as a percentage of the maximum possible score. It warns that a 50% score can mean steady middle ranks or a split between top and bottom ([MeetingPulse](https://help.meetingpulse.net/en/articles/2441324-preference-order-poll-results)).

Two lessons follow. First, tools disagree on which way the number points. SurveyMonkey turns ranks into weights, so the most preferred answer has the largest value. Typeform shows "the average ranking of each option," where a lower number is better ([Typeform](https://help.typeform.com/hc/en-us/articles/360052767651-Ranking-question)). Flick's totals already point the SurveyMonkey way, and the results page should say so ("more points is better"). Second, a total hides how it was earned, as MeetingPulse's 50% warning shows. A per-rank breakdown, like Award Force's columns or SurveyMonkey's distribution, shows whether an answer won on first ranks or on many fifths.

CCD's results research adds two rules. Show the winner before explaining the count, "visually as well as in text" ([CCD 2017, p. 36](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=36)). Align numbers next to the bars so readers can "add them up to check that they balance" ([CCD 2017, p. 40](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=40)).

### Round-by-round and flow charts

RCVis, an open-source visualizer for ranked-choice elections, offers round-by-round bar charts, Sankey diagrams, pie charts, and tables by round or by candidate ([RCVis](https://www.rcvis.com/)). RankedVote.co shows "Round-by-Round Details" and a visualization of "eliminations and vote redistributions" ([RankedVote.co features](https://www.rankedvote.co/guides/using-rankedvote/key-features)). These displays explain how votes transfer when an answer is eliminated. Flick's tally has no rounds and no transfers, so these displays would mislead.

### Early results

Tools treat live results as an organizer setting. OpaVote's "Show results during voting" lets voters "see preliminary results while voting is ongoing," and "the manager can only see preliminary results if the voters can also see preliminary results" ([OpaVote help](https://opavote.com/help/online-elections)). Slido organizers "Choose whether your live poll results will be visible or hidden for participants" ([Slido](https://community.slido.com/live-polls-quizzes-and-surveys-55/run-a-ranking-poll-727)). Pigeonhole Live has a setting that lets attendees "see the live results ... after voting" ([Pigeonhole Live](https://help.pigeonholelive.com/hc/en-us/articles/58064534705689-Ranking-Polls)). A StrawPoll results page can stay hidden until the deadline ([StrawPoll results](https://strawpoll.com/YVyPmJaXBnN/results)). CCD lists, as an open question, how to order answers "if results are shared as counting proceeds" ([CCD 2017, p. 43](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=43)).

Flick shows early results only on the ballot admin page, and it opens the public results page when the ballot closes (`lib/flick_web/live/vote/results_live.ex`). That default suits a points count, where one heavy vote can change the leader. The admin view should say the results are provisional and show how many votes they include.

### Weights

OpaVote supports weighted voters. A voter with weight 3 "would have his or her vote count 3 times" ([OpaVote help](https://opavote.com/help/online-elections)). Flick's weights are floats, so totals can be fractional: a 1.5 weight on a third rank gives 4.5 points. CCD notes that "Whole numbers are easier to read," though "none of our participants complained about the decimal places" ([CCD 2017, p. 36](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=36)). Show points with at most one decimal. Show the vote count beside the total, so a reader can tell when weights are at work.

## Accessibility

### Drag to reorder

WCAG 2.2 success criterion 2.5.7 (AA) requires that "All functionality that uses a dragging movement for operation can be achieved by a single pointer without dragging." Its example is a sortable list with "adjacent controls for moving the element up or down in the list." Keyboard support alone does not meet it ([W3C, Understanding 2.5.7](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements)).

Drag libraries differ on keyboard support:

- **SortableJS** has none. Asked in 2017 about keyboard and ARIA support, a maintainer answered "No," because "such a feature will increase the complexity of the entire solution by about a third" ([SortableJS #1176](https://github.com/SortableJS/Sortable/issues/1176)). A 2020 follow-up is still open ([#1951](https://github.com/SortableJS/Sortable/issues/1951)).
- **dnd-kit** (`@dnd-kit/core`, now documented as legacy) has a keyboard sensor, live-region announcements, and default instructions: "To pick up a draggable item, press space or enter. While dragging, use the arrow keys to move the item in any given direction. Press space or enter again to drop the item in its new position, or press escape to cancel" ([dnd-kit](https://dndkit.com/legacy/guides/accessibility/)).
- **Atlassian Pragmatic drag and drop** leaves accessible controls out of its core package and steers teams away from keyboard dragging. Its guidance says "Directional arrow movement doesn't always make sense when you can't see the interface you are engaging with," and that it requires "JAWS screen reader users to change screen reader mode." It recommends a menu of move actions, focus that returns to the trigger, and live-region messages that name the item and its old and new position ([Atlassian](https://atlassian.design/components/pragmatic-drag-and-drop/accessibility-guidelines)).

GitHub's accessibility team hit the same conflicts when it built a sortable list. "Arrow keys are commonly used by screen readers to help users navigate through content," NVDA fires mouse events on Enter, and fast moves make live announcements lag. For voice control and long lists, GitHub added a move dialog with "action" and "position" fields ([GitHub blog, 2024](https://github.blog/engineering/user-experience/exploring-the-challenges-in-creating-an-accessible-sortable-list-drag-and-drop/)).

The W3C's rearrangeable listbox example uses visible buttons, Alt+Up and Alt+Down shortcuts, and live-region confirmations. It warns of "support gaps in some browser and assistive technology combinations, especially for mobile/touch devices," and says its code "is not intended for production environments" ([W3C APG](https://www.w3.org/WAI/ARIA/apg/patterns/listbox/examples/listbox-rearrangeable/)).

The sources agree: visible buttons are the primary path, and drag is a shortcut. Flick's editor already pairs SortableJS with up and down buttons and returns focus to the moved row (`assets/js/hooks/sortable_inputs_for.js`). The vote page can reuse that design inside its five ranked slots.

### Ranked-choice ballot guidance

CCD tested its accessible ranked-choice ballot with 15 participants, including 6 blind voters, voters with no use of their hands, and voters with attention or cognitive disabilities ([CCD 2022, p. 23](https://civicdesign.org/wp-content/uploads/2022/10/CCD-RCV-Best-Practices-Ballot-Design-2022-1.pdf#page=23)). These practices from its 2024 guidance carry over to a web page ([CCD 2024](https://civicdesign.org/wp-content/uploads/2024/09/CCD-RCV-Best-Practices-Accessible-Ballot-Design-2024.pdf#page=3)):

- Voters select answers in rank order and can change a rank later.
- The list moves only when the voter asks. Automatic reordering "is disorienting," and participants "trusted the system less when it seemed like it was making decisions for them."
- The audio matches the screen one to one, including rank progress. On the web, that means the screen reader hears each answer's rank state and the count of ranks left.
- A review step lists rankings in order and flags "under-ranking."

CCD's 2017 study found that participants "liked having clear visible buttons." Gestures like drag "could not be the only (or even primary) way to interact with the ballot and rank candidates" ([CCD 2017, p. 66](https://civicdesign.org/wp-content/uploads/2017/07/RCV-Principles-and-Guidelines-FINAL-2017-0307.pdf#page=66)).

### Touch targets

WCAG 2.5.8 (AA) sets a minimum target of "24 by 24 CSS pixels," with an exception for small targets that are spaced apart ([W3C, Understanding 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum)). Apple recommends controls of "at least 44 points x 44 points" ([Apple design tips](https://developer.apple.com/design/tips/)). The rank grid is where this matters most, because five ovals share one row.

## Implications for Flick

### The six directions

Each direction in [issue #254](https://github.com/zorn/flick/issues/254) can try a different pattern. Every vote page needs visible buttons for any move, a count of ranks left, and wrapped (not truncated) titles.

| Direction | Ranking pattern | Results display | Watch for |
| --- | --- | --- | --- |
| a. Library card | Tap in order. A tap stamps the rank (1 to 5) on the answer's row, like a due-date stamp. The list stays in ballot order. | A checkout-card ledger: points plus a 1st-to-5th breakdown | The stamp must also be text, so a screen reader hears the rank |
| b. Pick Flick | Pick, then order. A tap pins the answer to a five-slot "ticket" with up, down, and remove buttons. | Campaign-poster bars, winner first | A long title inside a slot |
| c. Official ballot | Rank grid with five columns, CCD's instruction text, and gap and duplicate warnings | A tally sheet: counts per rank times points, then the total | 100 rows, column headers that scroll away, and title width on a phone |
| d. Swiss minimal | Five huge numbered slots. Tapping a slot opens a full-screen, filterable answer list, a better dropdown per rank. | A typographic ordered list with thin bars and exact points | Gaps, if a voter fills slot 3 first |
| e. Soft and tactile | Pick, then order, with drag inside the five ranked cards and move buttons beside it | Bars and a small celebration for the winner | Drag must not be the only way to move a card |
| f. Elixir after dark | Number per answer, keyboard-first: type 1 to 5 beside an answer, with a filter box | A monospace table with the rank breakdown | Duplicates, gaps, and 100 inputs |

On every ballot admin page, early results should carry a "provisional" label, the vote count, and the same breakdown as the results page.

### What breaks at 100 answers or with long text

- **Dropdown per rank.** Five selects of 100 entries each, and the closed select cuts off a long title.
- **Full-list drag.** 5 to 7 rows fit on a phone, the drag to the top is long, and ranks 6 to 100 mean nothing.
- **Rank grid.** 100 rows, column headers that scroll out of view, and less than half a phone's width for the title.
- **Number per answer.** 100 controls to scan, plus duplicates and gaps to catch.
- **Pairwise comparison.** 4,950 pairs, and no top five at the end.
- **Results list.** Up to 100 rows. Lead with the answers that earned points, and fold the answers with zero points, as Mentimeter puts unselected items at the bottom.

Tap in order and pick, then order survive both limits if the page adds a filter for long ballots and lets titles wrap. [Issue #81](https://github.com/zorn/flick/issues/81) tracks today's long-answer bug.
