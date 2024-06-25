# Decision: Vote Data Shape

## Ballots

`Flick.Ballots.Ballot` entity values have many `Flick.Ballots.Question`s and each question needs a list of possible answers. 

We could solve "possible answers" in the data model in multiple ways but have picked a specific style with intent.

While a more normalized implementation of this relationship would have a dedicated embedded schema for `PossibleAnswer` to keep the `Flick.Ballots.Ballot` schema more aligned with expected frontend needs when the ballot embeds a `Flick.Ballots.Question` value, we'll store the `possible_answers` as a simple string value. 

We expect `possible_answers` to be a comma-separated list of values and have some basic validations around this inside of `Flick.Ballots.Question`.

This decision was made with frontend practicality in mind. We've simplified the frontend UI by eliminating the need for a second layer of `inputs_for` for an alternative `PossibleAnswer` schema design. 

Instead, we ask the user to input a simple comma-separated list of values as part of a more simple UI experience.

## Votes

When capturing the votes, one might imagine a vote to have a `ballot_id` and then a list of ordered `answer_id` values for each question. Given the above-described storage of `possible_answers`, we don't have answer id values. 

When we capture a vote, we will store an answer as a string value, the exact same string that makes up the possible answer. 

This will duplicate the answer strings many times in the database; however, given the expected early usage of this app and the fact that a UUID can cost as much as many of these smaller answer values, this seems like an acceptable tradeoff for now. If we want to refactor, we can do so in the future.

To prevent recorded votes from becoming misaligned with edited answers, we'll introduce a publish event for a ballot, making it non-editable by users.
