# Secret scanning for Flick

Researched 2026-09-29 for issue #227. The tools checked were GitHub secret scanning (docs at [github/docs `main`](https://github.com/github/docs)), gitleaks 8.30.1 (released 2026-03-21), gitleaks-action v3.0.0 (2026-05-30), Betterleaks 1.8.1 (2026-08-18), and TruffleHog 3.97.9 (2026-09-24). `zorn/flick` is a public repository owned by a personal account.

## Answer

1. **Keep secret scanning and push protection on, as they are today.** They are free for public repositories, and they cover the full history plus issues and pull requests. They block provider tokens (AWS, Stripe, GitHub, and similar) at push time. No settings change is needed.
2. **Leave generic (non-provider) patterns and validity checks off. They are not available to Flick.** GitHub's docs list both features for organization-owned repositories with GitHub Secret Protection only. The API reports them as `disabled` for this repository, but that does not mean they can be enabled. AI password detection and custom patterns have the same limit.
3. **Add one generic scanner in CI, and choose Betterleaks.** GitHub's free tier has no pattern for the secrets Flick actually has: `SECRET_KEY_BASE`, the Basic Auth password, a Postgres `DATABASE_URL`, and a Render API key. In a probe with planted fake values, Betterleaks caught 6 of 7, gitleaks caught 5 of 7, and TruffleHog caught 2 of 7. Gitleaks is now frozen to security fixes only, and its author develops Betterleaks as the successor. Betterleaks accepts the gitleaks CLI flags and the `.gitleaksignore` format. Run the pinned release binary in `code-quality.yaml`, with `fetch-depth: 0`. Do not use gitleaks-action. It is free for personal accounts, but its license is not open source, and it adds nothing that a plain CLI step does not.
4. **Handle the known false positives with a committed `.betterleaksignore` of fingerprints, not with path allowlists.** A full-history scan finds 9 findings, and all 9 are false positives: dev/test `secret_key_base` values and dev/test passwords such as `postgres` and `unsafe-password`. An ignore file with those 9 fingerprints silences them. A new real secret in `config/dev.exs` would still fail CI, which a path allowlist would hide.
5. **Do not add a scanner to `mix precommit`.** The alias contains only Mix tasks. A scanner there would make every contributor install an extra Go binary, and nothing enforces the alias. Push protection already stops provider tokens before they reach GitHub, and CI catches generic secrets before merge. The remaining gap is a generic secret pushed to a public PR branch before CI runs. A personal git hook (`betterleaks git --pre-commit --staged`) closes that gap for anyone who wants one. It does not belong in the repository's required workflow.

Anything not called out above stands as recommended.

## What each layer catches

| Secret in Flick | GitHub (free, public) | gitleaks 8.30.1 | Betterleaks 1.8.1 | TruffleHog 3.97.9 |
| --- | --- | --- | --- | --- |
| Provider tokens (AWS, Stripe, GitHub, and so on) | Yes, and blocks the push | Yes | Yes | Yes, and verifies them live |
| `SECRET_KEY_BASE` | No | Yes (`generic-api-key`) | Yes | No |
| Basic Auth password | No | Yes (`generic-api-key`) | Yes (`generic-password`) | No |
| Postgres `DATABASE_URL` with password | No (org-only generic pattern) | No | In `.exs`, yes; in `.env`, no | Yes (`Postgres` detector) |
| Render API key (`rnd_…`) | No provider pattern | Yes, as a generic key | Yes (`render-api-key`) | No detector |
| Phoenix `signing_salt` (8 chars) | No | No | No | No |

The "Verification" section below has the probe method.

### GitHub native

Secret scanning "runs automatically for free" on public repositories ([gated-features/secret-scanning.md](https://github.com/github/docs/blob/main/data/reusables/gated-features/secret-scanning.md)). It "scans your entire Git history on all branches," and it also scans issues, pull requests, discussions, and wikis ([concepts/secret-scanning.md](https://github.com/github/docs/blob/main/content/code-security/concepts/secret-security/secret-scanning.md)). In a public repository, GitHub reports partner secrets to the issuing provider. They "aren't displayed in your repository alerts" ([same page](https://github.com/github/docs/blob/main/content/code-security/concepts/secret-security/secret-scanning.md)).

Push protection by default covers most provider patterns. It covers no generic or AI-detected patterns ([supported patterns table](https://github.com/github/docs/blob/main/content/code-security/reference/secret-security/supported-secret-scanning-patterns.md)). It "only blocks leaked secrets on a subset of the most identifiable user-alerted patterns," and it skips pushes to public repositories that are larger than 50 MB ([secret-scanning-scope.md](https://github.com/github/docs/blob/main/content/code-security/reference/secret-security/secret-scanning-scope.md)). Push protection for users is on by default, and it covers pushes to any public repository, including Flick ([push-protection.md](https://github.com/github/docs/blob/main/content/code-security/concepts/secret-security/push-protection.md)). The docs say that repository-level push protection "requires GitHub Secret Protection" ([same page](https://github.com/github/docs/blob/main/content/code-security/concepts/secret-security/push-protection.md)). Even so, the API reports it as `enabled` on this free public repository.

The GitHub pattern list has no Render pattern. Its only Postgres URL patterns are for Heroku and Snowflake ([pattern data, fpt](https://github.com/github/docs/blob/main/src/secret-scanning/data/pattern-docs/fpt/public-docs.yml)).

Generic patterns cover private keys, Postgres, MySQL, and MongoDB connection strings, and HTTP Basic and Bearer headers ([supported patterns](https://github.com/github/docs/blob/main/content/code-security/reference/secret-security/supported-secret-scanning-patterns.md)). They would catch a Render `DATABASE_URL`, but they are available only on "organization-owned repositories on GitHub Team with GitHub Secret Protection enabled" ([gated-features/secret-scanning-non-provider-patterns.md](https://github.com/github/docs/blob/main/data/reusables/gated-features/secret-scanning-non-provider-patterns.md)). Validity checks have the same organization-only limit ([gated-features/partner-pattern-validity-check-ghas.md](https://github.com/github/docs/blob/main/data/reusables/gated-features/partner-pattern-validity-check-ghas.md)), and they do not work on generic patterns anyway ([supported patterns](https://github.com/github/docs/blob/main/content/code-security/reference/secret-security/supported-secret-scanning-patterns.md)). AI password detection is available to "repositories owned by organizations and enterprises with GitHub Secret Protection enabled" ([copilot generic secrets note](https://github.com/github/docs/blob/main/data/reusables/secret-scanning/copilot-secret-scanning-generic-secrets-subscription-note.md)).

### gitleaks

Gitleaks is MIT-licensed and still receives commits ([repository](https://github.com/gitleaks/gitleaks)). However, its README now says: "Gitleaks is feature complete. I'm not merging new features into Gitleaks. Future releases will be security patches only. I'm shifting my focus to Betterleaks" ([README](https://github.com/gitleaks/gitleaks/blob/master/README.md)). The last release is v8.30.1, from 2026-03-21. Its rule set will not gain new token formats.

To handle false positives, gitleaks offers `[[allowlists]]` in `.gitleaks.toml`, a `.gitleaksignore` file of finding fingerprints, `gitleaks:allow` line comments, and `--baseline-path` ([README](https://github.com/gitleaks/gitleaks/blob/master/README.md)).

gitleaks-action v3 moved the action to Node 24. v2 stops working on 2026-09-16, when GitHub removes Node 20 from its runners. A license key is "only required for Organizations, not personal accounts." Since v2.0.0, the action uses a custom license instead of MIT ([gitleaks-action README](https://github.com/gitleaks/gitleaks-action/blob/master/README.md)). GitHub reports its license as `NOASSERTION`.

### Betterleaks

Betterleaks is MIT-licensed and was created on 2026-02-03. It is "maintained by the folks who made Gitleaks, including the original author," with development funded by Aikido Security ([README](https://github.com/betterleaks/betterleaks/blob/main/README.md)). Its releases are frequent (v1.7.4 on 2026-08-10 and v1.8.0 and v1.8.1 on 2026-08-18, per [releases](https://github.com/betterleaks/betterleaks/releases)).

Betterleaks keeps the gitleaks CLI shape. It has `git --pre-commit --staged`, `--baseline-path`, and `--redact`. It reads `.betterleaksignore` or `.gitleaksignore`, and it honors `gitleaks:allow` and `betterleaks:allow` comments (`betterleaks git --help`, v1.8.1). Filters are written in Expr instead of static allowlists. The README recommends maintaining your own config instead of extending the upstream default, so that rules stay stable across upgrades ([README](https://github.com/betterleaks/betterleaks/blob/main/README.md)). Flick does not need a custom config, because the ignore file handles the only noise.

Betterleaks has no official GitHub Action. The organization publishes only the tool, a Homebrew tap, and `go-re2` ([org repos](https://github.com/betterleaks)). Releases ship Linux tarballs with `checksums.txt` and a Sigstore bundle ([v1.8.1 assets](https://github.com/betterleaks/betterleaks/releases/tag/v1.8.1)), so a CI step can download a pinned release and verify it.

### TruffleHog

TruffleHog is AGPL-3.0 and actively released ([repository](https://github.com/trufflesecurity/trufflehog)). It uses provider-specific detectors, and the README claims "over 700 credential detectors that support active verification" ([README](https://github.com/trufflesecurity/trufflehog/blob/main/README.md)). It has no generic high-entropy or keyword rule. It therefore overlaps heavily with GitHub's provider coverage and misses `SECRET_KEY_BASE` and passwords. Its one advantage for Flick is the `Postgres` detector, which matched a database URL in both `.exs` and `.env`.

The official action runs `trufflehog@main` with `--results=verified,unknown` ([README, GitHub Action section](https://github.com/trufflesecurity/trufflehog/blob/main/README.md#octocat-trufflehog-github-action)). Any adoption should pin a tag instead of `main`. False positives are suppressed with `trufflehog:ignore` comments or `--exclude-detectors` ([README FAQ](https://github.com/trufflesecurity/trufflehog/blob/main/README.md)).

## How Phoenix dev and test values are treated

`config/dev.exs:26` and `config/test.exs:20` commit `secret_key_base` values. This is normal for Phoenix, because production reads `SECRET_KEY_BASE` in `config/runtime.exs`. Gitleaks and Betterleaks flag both values as `generic-api-key`. GitHub and TruffleHog ignore them.

The signing salts (`config/config.exs:27` and `lib/flick_web/endpoint.ex:11`) are 8 characters long. All four scanners ignore them.

Betterleaks also flags dev and test passwords (`postgres` and `unsafe-password`) in `config/*.exs`, `compose.yml`, `build-and-test.yaml`, and a doc example in `test/support/data_case.ex`. Gitleaks does not flag these.

The committed `password: System.get_env("BASIC_AUTH_ADMIN_PASSWORD", "unsafe-password")` in `config/config.exs:35` is not flagged at HEAD by any tool.

## Suggested CI step

Add a job to `.github/workflows/code-quality.yaml` that checks out with `fetch-depth: 0`, downloads `betterleaks_<version>_linux_x64.tar.gz`, verifies it against `checksums.txt`, and runs `betterleaks git . --redact --no-banner`. The exit code of 1 fails the job. Commit `.betterleaksignore` with the 9 current fingerprints. Dependabot does not track a version pinned in a `run:` script, so bump it by hand.

## Verification

All scans ran read-only against this checkout on 2026-09-29, using binaries in the session scratchpad. They covered 100 commits and about 730 KB of history. No secret values are reproduced here.

- **GitHub alerts:** `gh api repos/zorn/flick/secret-scanning/alerts` returned 0 alerts.
- **gitleaks 8.30.1 (`gitleaks git .`):** 2 findings in 0.14 s, both `generic-api-key` on the dev and test `secret_key_base`. Both are false positives.
- **Betterleaks 1.8.1 (`betterleaks git .`):** 9 findings in 0.7 s. Two are the `secret_key_base` values. Seven are `generic-password` on dev and test Postgres or Basic Auth defaults, including one on the `password: "short"` doc example in `data_case.ex`. All 9 are false positives. A `.betterleaksignore` with their 9 fingerprints brought the scan to "no leaks found," with exit code 0.
- **TruffleHog 3.97.9 (`trufflehog git file://. --no-update`):** 0 verified, unverified, or unknown results in 0.25 s.
- **`gitleaks dir .` on the working tree:** 45 s over 405 MB, because it walks `deps/` and `_build/`. It found 5 extra false positives in `deps/`. Scan git history (`git`) or staged changes, not the directory.
- **Planted-secret probe:** A scratch directory held a fake `config/prod.exs` and `.env`. They contained a random `SECRET_KEY_BASE`, a Render-style Postgres URL with a password, a Basic Auth password, and a `rnd_`-prefixed Render API key, for 7 planted values. Gitleaks caught 5 and missed both database URLs. Betterleaks caught 6 and missed the `postgresql://` URL in `.env`. TruffleHog caught the 2 database URLs as `unknown` after its verification attempt failed, and caught nothing else.

Not verified: GitHub's own response to the planted values, because that would need a push to GitHub. The coverage for GitHub in the table comes from its published pattern list, not from a probe. Also not verified: that the repository settings page refuses to enable generic patterns. No settings were changed.
