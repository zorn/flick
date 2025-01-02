> Users should be able to close a ballot, allowing no more voting.

Currently we have two states for a ballot.

published and unpublished

this is managed by the `:published_at` field which currently can be `nil`.

Feel like we introduce a `status` field. `unpublished`, `published` and `closed`.

Remove `published_at` from being in the normal changeset. document and test this.

Introduce a new function to `close_ballot`.

Enforce state changes so there can only be one direction.

Maybe do three diferent `render` templates for the show page depending on status.

If we don't care about when a ballot was published or closed, it makes the status easier, a simple three value enum.

If we need to know its status and when the status changed we'd need to save a rich JSON value

We could also just add `closed_at` and then derive a status with a funcion.

If feels like the status of a ballot, even in this simple use is starting to outgrow being attached to the ballot directly. 
