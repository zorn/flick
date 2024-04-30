# Decision: Timestamps

# Problem Statement

Out of the box, when you use the Ecto [`timestamps/1` function][1], you end up with `:naive_datetime` values for in-memory entities. This lacks the level of timezone precision we would prefer.

[1]: https://hexdocs.pm/ecto/Ecto.Schema.html#timestamps/1

## Solution

Our upcoming Ecto schemas will use `timestamps(type::utc_datetime_usec)` to be explicit about UTC and use microseconds for more precision.

When creating the database columns in our migration files, we will also use `timestamps(type::utc_datetime_usec)`. This results in the database column having a type like `timestamp without time zone NOT NULL`. 

Take note this Postgres column type does not have any timezone information. We assume the database will always store timestamp values in UTC (which is a community norm).

## Other Solutions Considered

### `timestamptz`

We could have used a database migration style with `timestamps(type: :timestamptz)`, which would store timezone information in the Postgres database, **but** that also encourages people to store non-UTC timestamps in the database. For clarity, we would prefer the database always be UTC. 

This is not an irreversible decision and can be adjusted if wanted.

### What are timestamps?

An argument can be made that the timestamp columns of the database are metadata of the implementation and should not be viewed as domain-specific values. The logic goes: If you want to track when your domain entities are created with your specific domain perspective, you should have `created_at` and `edited_at` columns. Those database-specific `inserted_at` and `updated_at` columns may change due to implementation needs and not accurately represent the actual domain knowledge.

That said, for the sake of simplicity, we are **not** going to introduce `created_at` and `edited_at` and will continue to make the `inserted_at` and `updated_at` values available to the Elixir code. Should these columns deviate from the domain interpretation, we can add those other columns later.
