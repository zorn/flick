# Decision: Ballot and Vote Schema Shape

## Ballots

The `Flick.Ballots.Ballot` schema captures a simple one-question ballot using fields for `question_title` and `possible_answers`.

We could have solved "possible answers" in the data model in multiple ways but have picked this specific style with intent.

We expect `possible_answers` to be a comma-separated list of values and have some basic validations around this. This decision was made with frontend practicality in mind. We've simplified the frontend UI by eliminating the need for a second layer of `inputs_for` for an alternative `PossibleAnswer` `embeds_many` schema design.

Additionally, early drafts of this schema allowed a ballot to have multiple questions, but again, we've chosen to simplify for now.

## Votes

When capturing votes, one might imagine a vote to have a `ballot_id` and then a list of ordered `answer_id` values. Given the above-described storage of `possible_answers`, we don't have answer id values. 

When we capture a vote, we store an answer as a string value, the same string defined in the possible answer. 

This will duplicate the answer strings many times in the database; however, given the expected early usage of this app and the fact that a UUID value can cost as much as many of these smaller answer values, this is an acceptable tradeoff for now. If we want to refactor, we can do so in the future.

To prevent recorded votes from becoming misaligned with edited answers, we'll introduce a publish event for a ballot, [making it non-editable by users](https://github.com/zorn/flick/issues/13).
