# Ecto

- Preload every association a template reads, in the query that loads the record.
- Read a changeset's fields with `Ecto.Changeset.get_field/2`.
- List in `cast/3` only the fields a user may set. Set fields the server controls directly on the struct, as `Flick.RankedVoting.Vote` does with `ballot_id`.
- `validate_number/3` already skips a nil value, so pass it only the bounds.
- Create a migration with `mix ecto.gen.migration migration_name_using_underscores`, which sets the timestamp and file name.
