# Decision: FIXME and TODO

We use [Credo](https://github.com/rrrene/credo) to help enforce style rules for
the code. Credo has configurable rules for `FIXME` and `TODO`; this project
deviates from the default config, so this decision documents expectations.

## FIXME

Feel free to include `FIXME` comments in your code, preferably with a URL to the
GitHub Issue that captures the future work. Credo will not balk at FIXME
comments.

## TODO

`TODO` comments are meant as actionable signals for work that remains to be done
before a branch is considered complete and can be merged into `main`. Credo will
report on `TODO` comments, and they will need to be resolved/removed to pass PR
checks.
