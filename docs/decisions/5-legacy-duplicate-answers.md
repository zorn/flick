# Decision: Legacy Duplicate Answers

Possible answers must now be unique, ignoring case, but twelve published or
closed ballots in production already repeat an answer: eleven exactly, one only
in case. The migration to embeds ([Decision 4](4-possible-answers-as-embeds.md))
carries them over unchanged, with no flag and no migration guard.

Those ballots can no longer be edited, and their votes reference the repeated
text. Removing duplicates would change historical results, and removing case
variants would orphan votes. A flag would record something no code acts on and
a query can already find. A guard would only add a way for the deploy to fail.

The uniqueness rule runs whenever an answer list changes, so every new ballot
and every draft edit is held to it. The cost is cosmetic: the affected ballots
list the repeated answer twice in the vote dropdown and in results, with
identical points.

Context: [#203](https://github.com/zorn/flick/issues/203),
[#201](https://github.com/zorn/flick/issues/201).
