# Decision: Vote Data Shape

## Context

To keep the `Flick.Ballots.Ballot` schema more straightforward when it embeds a `Flick.Ballots.Question` value, we store the `possible_answers` as a simple string. We expect it to include comma-separated values and have some basic validations around this. 

This decision was made with practicality in mind. By simplifying the frontend UI, we've eliminated the need for a second layer of `inputs_for` for answers. Instead, we ask the user to input a simple comma-separated list of values. 

## Problem Statement

When capturing the votes, one might imagine a vote to have a `ballot_id` and then a list of ordered `answer_id` values for each question. Given the storage of `possible_answers`, we don't have answers withs id values.

## Solution

When we capture a vote, we will store a list of string values. This will duplicate the answer strings many times in the database; however, given the expected early usage of this app and the fact that a UUID can cost as much as many of these answer values, this seems like an acceptable tradeoff for now.

## Other Solutions Considered

When a ballot is published, we could generate a list of possible answer entities with identities. When votes are recorded, we would then reference these identities as part of the persistence. This could result in more streamlined storage and better querying down the road.

Maybe someday, when the answers are more complex than a simple string, this will make sense, but for now, we will not choose this path.
