# Ecto length validation and Postgres column limits count different things, and the community began aligning them in September 2026

Researched 2026-10-06 for [PR #261](https://github.com/zorn/flick/pull/261) and [issue #229](https://github.com/zorn/flick/issues/229) against Ecto 3.14.2 (the version in `mix.lock`), Ecto `master` at `94d69279`, ecto_sql 3.14.0, Phoenix 1.8.15, Ash 3.33, the PostgreSQL 18 docs, and Elixir 1.20. The counts in the table below were run in Elixir 1.20.1 and on a local PostgreSQL 14.17 with `UTF8` server encoding. GitHub code-search counts come from the REST search API on 2026-10-06.

## Answer

1. **Yes, the community considers it, and Ecto's own docs have warned about it since 2017.** The `validate_length/3` docs in the current release say: "Note that the length of a string is counted in graphemes by default. If using this validation to match a character limit of a database backend, it's likely that the limit ignores graphemes and limits the number of unicode characters. Then consider using the `:count` option to limit the number of codepoints (`:codepoints`), or limit the number of bytes (`:bytes`)." ([hexdocs](https://hexdocs.pm/ecto/Ecto.Changeset.html#validate_length/3)). Alvin Lindstam added the note and the `:count` option together in [PR #2184](https://github.com/elixir-ecto/ecto/pull/2184), merged 2017-08-25 and first released in Ecto 3.0.0. @ishikawa extended the note with `:bytes` in [PR #2826](https://github.com/elixir-ecto/ecto/pull/2826), released in 3.0.3.
2. **Ecto is about to make PR #261's choice the default.** On 2026-09-03 José Valim committed "Count codepoints by default" to Ecto `master` ([11784f82](https://github.com/elixir-ecto/ecto/commit/11784f821a1bb0eedeee59583e311d836cb39ee1)). The unreleased 3.15.0 changelog says the change aligns `validate_length/3` "with how databases typically enforce string length limits." The latest release on Hex is still 3.14.2, which counts graphemes. The commit has no linked pull request, so its public motive rests on the changelog line alone.
3. **The trigger was security, not the `22001` crash.** A grapheme has no upper size: one base letter plus a million combining marks is one grapheme and 2 MB. Ash published [CVE-2026-82752](https://github.com/ash-project/ash/security/advisories/GHSA-cwjv-574p-59f6) on 2026-09-05 because a grapheme-counted `max_length` "constrains nothing." Hex.pm's [PR #1904](https://github.com/hexpm/hexpm/pull/1904), merged the same day as the Ecto commit, opens with "a grapheme has no upper size, so `max: n` bounded nothing." Plausible and OpenFn Lightning followed within a week. The mismatch with `varchar(n)` is the second-order effect in each write-up.
4. **Explicit counts are rare.** About 320 Elixir files on GitHub pass `count: :codepoints` or a non-password `count: :bytes` to `validate_length`, against about 15,000 files that call it. Most `count: :bytes` hits (about 1,800 of 2,300) are the bcrypt line that `phx.gen.auth` emits, not a deliberate choice. The search counts files, not calls, so treat these as orders of magnitude.
5. **The risk is real but narrow on a `varchar(n)` column, and wider on an unbounded one.** On `varchar(255)`, an over-long value raises `Postgrex.Error` `22001` and the column still bounds storage, so the failure is a crash, not data loss. On a `text` or `jsonb` column, a grapheme-counted limit lets any size through. In Flick, `PossibleAnswer.value` is capped at 500 graphemes inside a `jsonb` column, so that cap bounds nothing today.

## How each layer counts

Each layer counts a different unit, and only two of them agree.

| Layer | Unit | Source |
| --- | --- | --- |
| `validate_length/3`, Ecto 3.14 default | Graphemes, through `String.length/1` | [changeset.ex](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/changeset.ex#L3044-L3123) |
| `validate_length/3`, `count: :codepoints`, and the 3.15 default | Code points | [changeset.ex](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/changeset.ex#L3121-L3123), [11784f82](https://github.com/elixir-ecto/ecto/commit/11784f821a1bb0eedeee59583e311d836cb39ee1) |
| `validate_length/3`, `count: :bytes` | UTF-8 bytes, through `byte_size/1` | [changeset.ex](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/changeset.ex#L3102-L3103) |
| Postgres `varchar(n)`, `char_length`, `length` | Characters, which in `UTF8` are code points | [Character types](https://www.postgresql.org/docs/current/datatype-character.html), [String functions](https://www.postgresql.org/docs/current/functions-string.html) |
| Postgres `octet_length` | Bytes in the server encoding | [String functions](https://www.postgresql.org/docs/current/functions-string.html) |
| HTML `maxlength` | UTF-16 code units | [WHATWG HTML](https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-maxlength), [Infra "length"](https://infra.spec.whatwg.org/#string-length) |

Worked examples, each counted in every unit:

| String | Graphemes | Code points (Postgres `char_length`) | UTF-8 bytes (`octet_length`) | UTF-16 code units (`maxlength`) |
| --- | --- | --- | --- | --- |
| `cafe` | 4 | 4 | 4 | 4 |
| `é` precomposed, U+00E9 | 1 | 1 | 2 | 1 |
| `é` decomposed, `e` + U+0301 | 1 | 2 | 3 | 2 |
| 😀 U+1F600 | 1 | 1 | 4 | 2 |
| 👨‍👩‍👧 ZWJ family (man, ZWJ, woman, ZWJ, girl) | 1 | 5 | 18 | 8 |
| 🇺🇸 flag (two regional indicators) | 1 | 2 | 8 | 4 |
| `e` + 1,000,000 × U+0301 | 1 | 1,000,001 | 2,000,001 | 1,000,001 |

The Elixir figures come from `String.length/1`, `String.codepoints/1`, `byte_size/1`, and a UTF-16 conversion. The Postgres figures come from `char_length` and `octet_length` on PostgreSQL 14.17. The grapheme count is always the smallest, so a grapheme limit is always the loosest. UTF-8 bytes are always at least the code-point count, so a byte limit of `n` always fits `varchar(n)`.

**Ecto.** `validate_length/3` reads `opts[:count] || :graphemes` and dispatches on it ([changeset.ex](https://github.com/elixir-ecto/ecto/blob/v3.14.2/lib/ecto/changeset.ex#L3089-L3104)). `:graphemes` calls `String.length/1`, which "Returns the number of Unicode graphemes in a UTF-8 string" ([Elixir String](https://hexdocs.pm/elixir/String.html#length/1)). `:codepoints` walks the binary with `<<_::utf8, rest::binary>>` and counts any invalid byte as one. `:bytes` calls `byte_size/1` and switches the error to "should be at most %{count} byte(s)". The two string counts share the message "should be at most %{count} character(s)". Elixir's [String module docs](https://hexdocs.pm/elixir/String.html#module-grapheme-clusters) explain that "Graphemes can consist of multiple code points that may be perceived as a single character by readers."

**Postgres.** `varchar(n)` stores "strings up to *n* characters (not bytes) in length." Storing a longer string "will result in an error, unless the excess characters are all spaces," but an explicit cast to `varchar(n)` truncates silently ([Character types](https://www.postgresql.org/docs/current/datatype-character.html)). The docs say "characters" without defining the term. In a `UTF8` database a character is a code point: `INSERT` of `e` + U+0301 into `varchar(1)` fails with "value too long for type character varying(1)," while `U&'e\0301'::varchar(1)` returns a bare `e`. The error is SQLSTATE `22001`, `string_data_right_truncation` ([Postgres error codes](https://www.postgresql.org/docs/current/errcodes-appendix.html)).

**Browsers.** `maxlength` "declares a limit on the number of characters a user can input," measured with Infra's length ([WHATWG HTML](https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-maxlength)). Infra defines "A string's length is the number of code units it contains" ([Infra](https://infra.spec.whatwg.org/#string-length)), which are UTF-16 code units. User agents "may prevent the user" from exceeding it, which in practice truncates a paste. An astral character such as an emoji costs two units, so `maxlength="255"` is stricter than `varchar(255)` for emoji and looser than nothing for combining marks. It is a client-side hint that a crafted request skips.

## History in Ecto

**2016: José wanted length errors caught as validations.** [Issue #1352](https://github.com/elixir-ecto/ecto/issues/1352) reported a crash on `value too long for type character varying(255)` and asked Ecto to return it as a changeset error. José declined: "I would actually like to know when those cases show up so we properly convert it to a changeset validation. Relying on the database specific checks is the only option sometimes but using changesets validations will provide the best user experience and performance." Michał Muskała added that an arbitrary database error "most often signify an error made by the programmer."

**2017: `:count` and the docs note.** Alvin Lindstam opened [PR #2184](https://github.com/elixir-ecto/ecto/pull/2184) because "Most databases ignore graphemes in the size limit for char fields, and only care about the number of code points." José pushed back first: "Counting codepoints is ultimately flawed for languages like korean. Can we please try to double check the database behaviour?" Lindstam showed that both MySQL and Postgres rejected `'ééééé'` in a five-character column, and replied: "I might not care about the number of user perceived characters, I just want to make sure that it fits in the column." Michał asked whether bytes would suit better. Lindstam answered that MySQL and Postgres limit `(var)char` "in characters (codepoints), not bytes or graphemes." José approved after supplying the faster `codepoints_length/2` that still ships. The PR added the docs note quoted in finding 1, and it first released in 3.0.0 on 2018-10-29 ([CHANGELOG](https://github.com/elixir-ecto/ecto/blob/v3.14.2/CHANGELOG.md)).

**2018: `:bytes`.** [PR #2826](https://github.com/elixir-ecto/ecto/pull/2826) added `count: :bytes` for binary data such as icons, and appended "or limit the number of bytes (`:bytes`)" to the note. The 3.0.3 changelog lists it ([CHANGELOG](https://github.com/elixir-ecto/ecto/blob/v3.14.2/CHANGELOG.md)).

**2026: codepoints by default.** Commit [11784f82](https://github.com/elixir-ecto/ecto/commit/11784f821a1bb0eedeee59583e311d836cb39ee1) flips the default, replaces the note with an info box ("The length of a string is counted in codepoints by default since v3.15.0"), and bumps the version to `3.15.0-dev`. Its test now expects `e` + U+0301 to fail `max: 1` unless `count: :graphemes` is passed. Ecto has published no security advisory for the grapheme behavior ([advisories](https://github.com/elixir-ecto/ecto/security/advisories)).

Searches of the Ecto tracker for "graphemes," "codepoints," and the Postgres error text found no other discussion. GitHub's issue search is keyword-based, so a thread that used other words could be missed.

## Prior art in open-source projects

**Phoenix.** `phx.gen.schema` emits only `validate_required` and `add :field, :string`, so a generated app starts with `varchar(255)` columns and no length check at all ([schema template](https://github.com/phoenixframework/phoenix/blob/v1.8.15/priv/templates/phx.gen.schema/schema.ex.eex)). `phx.gen.auth` emits `validate_length(:email, max: 160)` with the default grapheme count ([schema.ex.eex L41](https://github.com/phoenixframework/phoenix/blob/v1.8.15/priv/templates/phx.gen.auth/schema.ex.eex#L41)). On Postgres the email column is `citext` with no limit, while on MySQL and other adapters it is `:string, size: 160` ([migration.ex L26-L28](https://github.com/phoenixframework/phoenix/blob/v1.8.15/lib/mix/tasks/phx.gen.auth/migration.ex#L26-L28)). The email format regex permits non-ASCII, so on those adapters the grapheme check and the column disagree. For passwords it emits `max: 72` in graphemes, and adds `count: :bytes` only when the hashing library is bcrypt ([L86, L101](https://github.com/phoenixframework/phoenix/blob/v1.8.15/priv/templates/phx.gen.auth/schema.ex.eex#L86-L101)). Phoenix `main` is unchanged as of 2026-10-06.

**Hex.pm.** Eric Meadows-Jönsson's [PR #1904](https://github.com/hexpm/hexpm/pull/1904) (merged 2026-09-03) is the most thorough treatment found. Its rule: "`count: :codepoints` for anything a person types, with `n` equal to the column width where there is one, since `varchar(n)` counts codepoints; `count: :bytes` where a protocol counts octets." It also moved several `text` columns to `varchar(n)` so the changeset and the column carry the same limit. `users.full_name` is now `validate_length(:full_name, count: :codepoints, max: 255)` on a `varchar(255)`, the same shape as Flick's PR #261. "Minimums stay in graphemes."

**Ash.** [CVE-2026-82752](https://github.com/ash-project/ash/security/advisories/GHSA-cwjv-574p-59f6), fixed in Ash 3.33.0 on 2026-09-05, added a `length_count` constraint and a required `config :ash, :default_string_length_count` ([CHANGELOG](https://github.com/ash-project/ash/blob/main/CHANGELOG.md), [patch](https://github.com/ash-project/ash/commit/a64cab49b8886503e6b7c7b211d83c475aac48ca)). Its docs say "`:codepoints` matches how most SQL data layers count string length" and "Prefer `:codepoints` or `:bytes` when `max_length` is used as a storage or safety limit" ([string.ex](https://github.com/ash-project/ash/blob/main/lib/ash/type/string.ex)). The advisory notes that "A Postgres `varchar(n)` column bounds the value independently and is not exposed," but "a value Ash accepts can still be truncated or rejected by the column." Most `count: :codepoints` search hits are not `validate_length` calls at all: about 140 of the 236 are `config/` files, mostly `config :ash, default_string_length_count: :codepoints`.

**Plausible.** [PR #6617](https://github.com/plausible/analytics/pull/6617) (2026-09-08) caps team names at 50 graphemes for display and 255 bytes for storage. The code comment explains the byte choice: "`teams.name` is a varchar(255), which counts code points. Capping bytes keeps the column safe, since a code point is never shorter than a byte" ([team.ex](https://github.com/plausible/analytics/blob/main/lib/plausible/teams/team.ex)). Segment names and annotation notes use `count: :bytes, max: 255` too.

**OpenFn Lightning.** [PR #5106](https://github.com/OpenFn/lightning/pull/5106) (2026-09-09) allowed non-ASCII names and added a column-width check. Its docstring states the Flick problem exactly: "Postgres counts a varchar in codepoints; the product caps above this one count graphemes, so a name built from multi-codepoint clusters can pass a 100 grapheme cap and raise `22001` on insert" ([validators.ex](https://github.com/OpenFn/lightning/blob/main/lib/lightning/utils/validators.ex)).

**No explicit count.** Changelog.com (4 files), Livebook (1), Papercups (2), Oban (1), and TeslaMate (18) call `validate_length` without `:count`. Akkoma and `bonfire_common` returned no hits; Pleroma was not searched separately. These projects do not comment on the choice. A missing `:count` is not proof of a bug, since a field with an ASCII-only format check counts the same in every unit.

**How common.** REST code search on 2026-10-06 returned these file counts for `language:Elixir`:

| Query | Files |
| --- | --- |
| `validate_length` | 15,072 |
| `validate_length` with `"max: 255"` | 1,880 |
| `"count: :codepoints"` (any context, including Ash config) | 226 |
| `"count: :codepoints"` with `validate_length` | 83 |
| `"count: :graphemes"` | 148 |
| `"count: :bytes"` with `validate_length` | 2,288 |
| `"max: 72, count: :bytes"` (the `phx.gen.auth` bcrypt line) | 1,832 |
| `"count: :bytes"` with `validate_length`, excluding `password` | 242 |

Code search counts matching files, caps its index, and includes forks and tutorials. The ratio is the useful signal: deliberate non-default counts appear in roughly 2% of files that validate length (83 plus 242, against 15,072). The `count: :graphemes` hits are partly Ash's new explicit form and partly tests, so they do not show that projects chose graphemes on purpose.

## Other ways projects avoid the mismatch

**Use `:text` and drop the column limit.** The ecto_sql docs say `:string` "by default has a limit of 255 characters" and that "If you don't want to impose a limit, most databases support a `:text` type or similar" ([Ecto.Migration field types](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#module-field-types)). The Postgres adapter emits `varchar(255)` for a sizeless `:string` ([connection.ex](https://github.com/elixir-ecto/ecto_sql/blob/v3.14.0/lib/ecto/adapters/postgres/connection.ex)). Postgres reports "no performance difference among these three types" ([Character types](https://www.postgresql.org/docs/current/datatype-character.html)), and Flick already adopted `PreferTextColumns` for new migrations ([ecto-migration-safety.md](ecto-migration-safety.md)). This removes the crash, but it also removes the only hard bound, so the changeset must then count code points or bytes or the field becomes the Ash CVE.

**Add a check constraint and map it.** A `CHECK (char_length(col) <= n)` constraint plus `check_constraint/3` turns the violation into a changeset error instead of a raise ([Ecto.Changeset.check_constraint/3](https://hexdocs.pm/ecto/Ecto.Changeset.html#check_constraint/3)). None of the projects above did this for length; they validate in the changeset and let the column be the backstop.

**Catch the error.** Rescuing `Postgrex.Error` with code `22001` works, but José's 2016 answer in [issue #1352](https://github.com/elixir-ecto/ecto/issues/1352) argues for a changeset validation instead. No project found does this.

**Count bytes.** Plausible's reasoning shows that a byte limit of `n` always fits `varchar(n)`. It rejects legitimate non-Latin text early, which is why Hex.pm reserves bytes for protocol fields.

## Is the risk real?

**On `varchar(n)` it is a crash, not a breach.** A 255-grapheme name can hold far more than 255 code points: one combining mark per letter doubles it, and a single ZWJ family emoji is five. Hindi and Thai use combining vowel signs in ordinary words, and text copied from decomposed (NFD) sources, such as older macOS file names, splits accented Latin letters in two. Ecto 3.14 accepts such a value and the insert raises `22001`, which in a LiveView crashes the process. A crafted payload reaches it trivially; a real user reaches it rarely. No public Elixir bug report of a real user hitting it was found.

**On `text` or `jsonb` it is unbounded storage.** The Ash advisory shows the practical ceiling is the request size limit, "commonly `Plug.Parsers`' 8 MB default." In Flick, `PossibleAnswer` caps `value` at 500 graphemes ([possible_answer.ex](../../lib/flick/ranked_voting/possible_answer.ex)) and stores it in the `jsonb` column `ballots.possible_answers`, so the cap does not bound size. `Ballot.url_slug` uses graphemes on a `varchar(255)`, but its ASCII-only `validate_format` makes every unit agree.

**MySQL differs only in detail.** MySQL `CHAR` and `VARCHAR` lengths are "the maximum number of characters," and without strict mode an over-long value "is truncated to fit and a warning is generated" ([MySQL 8.4](https://dev.mysql.com/doc/refman/8.4/en/char.html)). Silent truncation is a worse failure than Postgres's error. The legacy 3-byte `utf8` (`utf8mb3`) charset cannot store 4-byte characters such as emoji at all. Flick runs on Postgres, so neither applies here.

**PR #261 matches where Ecto is heading.** Once Flick upgrades to Ecto 3.15, `count: :codepoints` on `full_name` becomes the default. Keeping it explicit still documents the intent and pins the behavior if a dependency pins Ecto lower.

## Blog post angle

- The docs have warned about the mismatch since 2017, so the interesting question is how often projects followed the note. The answer, roughly 2% of files, is under-discussed.
- The security framing is new and not yet widely written up for Elixir: a grapheme-counted `max` on a `text` column bounds nothing, and Ecto 3.15's default change fixes it silently for anyone who upgrades.
- September 2026 saw Ecto, Hex.pm, Ash, Plausible, and Lightning all move within a week. A timeline post would be novel, though the Ecto commit's motive is inferred, not stated.
- `phx.gen.auth` still emits grapheme-counted `max: 72` for non-bcrypt passwords, which bounds nothing before hashing. This deserves verification and probably an upstream issue before a post claims it.
- A demo project needs one `varchar(255)` field and one `text` field, a LiveView form, and a test per row of the worked-examples table. It should show the `22001` crash on Ecto 3.14, the unbounded `text` insert, the browser `maxlength` truncating a pasted emoji, and all three going away with `count: :codepoints` or on Ecto 3.15.
