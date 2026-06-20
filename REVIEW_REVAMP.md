# `revamp` Branch Review

**Branch:** `revamp` vs `main`  
**Version:** 1.3.5 → 1.4.0  
**Review date:** 2026-06-15  
**Commits reviewed:** 5 (`1e9a1b1` … `d470683`)

---

## Recommendation

**Conditional ship** — merge to `main` after addressing the **major** documentation/code mismatches below. No blocking test or build failures were found locally; security review found no medium+ issues. The core architecture is sound, but several user-facing behaviors contradict the README and should be fixed or explicitly documented before a 1.4.0 release.

---

## Phase 1 — Baseline verification

| Step | Result |
|------|--------|
| `gleam format --check src test` | PASS |
| `gleam check` | PASS |
| `gleam build` | PASS |
| `gleam test --target erlang` | PASS (31 tests) |
| `gleam test --target javascript --runtime nodejs` | PASS (31 tests) |
| `./scripts/target_test.sh erlang` | PASS |
| `./scripts/target_test.sh javascript nodejs` | PASS |
| Dogfood: `init` → hook contains `-m cactus --` | PASS |
| Dogfood: `--verbose --dry-run pre-commit` | PASS (stash + dry-run actions) |
| Dogfood: `clean` removes only cactus hooks | PASS |
| `gleam run -m go_over -- --outdated` | PASS (0 outdated packages) |
| `--help` CLI alias | PASS (parsed to `help` command) |

---

## Blocking issues

None — all automated checks pass.

---

## Major issues

### 1. Empty `files_scope` runs filtered actions (doc/code mismatch)

**Location:** `src/cactus/modified.gleam:152-156`, `test/modified_test.gleam:37-38`

`modified_files_match` returns `True` when `modified_files` is empty, even if `watched` (the `files` filter) is non-empty:

```gleam
list.is_empty(modified_files)
|| list.is_empty(watched)
|| list.any(watched, ...)
```

**README says** (lines 101–102): *"An action runs when any watched pattern matches any file in the chosen `files_scope`."*

**Actual behavior:** With `files = [".gleam"]` and `files_scope = "staged"`, if nothing is staged, the action **still runs**. Unit tests explicitly assert `modified_files_match([], [".foo", ".bar"])` is `true`.

**Impact:** Pre-commit linters/formatters with file filters may run unnecessarily when no matching files are in scope — opposite of documented and recommended `files_scope = "staged"` UX.

**Fix options:** Remove the `list.is_empty(modified_files)` short-circuit when `watched` is non-empty, or update README to document this behavior.

---

### 2. `skip_if = "ci"` treats any non-empty `CI` as skip signal

**Location:** `src/cactus/run.gleam:252-257`

```gleam
Some("ci") ->
  case envoy.get("CI") {
    Ok(value) -> value != ""
    Error(_) -> False
  }
```

**README says** (line 79): *"Skip all actions in this hook when CI=true"*

**Actual behavior:** `CI=false`, `CI=0`, or any other non-empty value also skips. Only unset `CI` runs actions.

**Impact:** Local developers with `CI=false` in shell profile may silently skip hooks.

**Fix:** Compare `string.lowercase(value)` to `"true"` or `"1"`.

---

### 3. README claims unrelated stashes prevent stashing — not implemented

**Location:** `README.md:131-132`, `src/cactus/git.gleam:46-56`

README states: *"If you already have unrelated stashes, cactus will not stash."*

**Actual behavior:** `stash_unstaged_in` always runs `git stash push` when there are local changes. No check for pre-existing stashes. Test `stash_unstaged_in_keeps_existing_stash_test` uses a **clean working tree** after creating a stash (returns `Ok(False)` due to no changes), not an unrelated-stash guard.

**Impact:** Misleading troubleshooting; users may expect protection that does not exist.

**Fix:** Either implement a pre-stash guard (`git stash list` check) or rewrite README to describe actual behavior (cactus always stashes when dirty; pop only pops cactus-tagged top stash).

---

### 4. Stash restore silently no-ops when top stash is not cactus-tagged

**Location:** `src/cactus/git.gleam:70-88`

If `git stash list -1` does not contain `cactus-pre-commit`, `pop_cactus_stash_in` returns `Ok("")` without error. Combined with `run_with_stash`, a pre-commit that successfully stashed could exit 0 while unstaged changes remain on the stash stack if the top entry is not the cactus stash (race or edge case).

**Impact:** Rare but high severity — silent loss of working-tree state after hook.

**Fix:** Return an error when `stashed == True` but pop finds no cactus-tagged top stash, or pop by stash message index.

---

### 5. Missing `CHANGELOG.md`

**Location:** `README.md:108` links to `CHANGELOG.md` which does not exist on the branch.

**Impact:** Broken link; no migration notes for 1.4.0 breaking changes (see below).

**Fix:** Add `CHANGELOG.md` with 1.4.0 entry or remove the link.

---

### 6. `merge_stash_pop_result` hides pop errors when hook also fails

**Location:** `src/cactus/run.gleam:455-463`

When both hook actions and `git stash pop` fail, only the hook `ActionFailedErr` is returned. User may not realize unstaged changes were not restored.

**Fix:** Combine error messages or prefer pop error when stash was taken.

---

## Minor issues

| # | Severity | Location | Finding |
|---|----------|----------|---------|
| 1 | minor | `test/testdata/gleam/fake.toml` | Not tracked in git; test passes because missing file returns `Error` as expected. Consider adding an explicit fixture for clarity. |
| 2 | minor | `test/testdata/gleam/exec.toml` | Uses hook names `test-skip`, `test-dry`, `test-hook` which are **not** in `write.valid_hooks` — cannot be exercised via `gleam run -m cactus -- <name>`. Only callable via `run.run()` in unit tests. |
| 3 | minor | `test/modified_test.gleam` | `glob_match_extension_test` asserts `src/foo.gleam` matches `*.gleam` — works via single-segment wildcard, but `wildcard_match` only handles one `*` per segment; patterns like `*.*.gleam` would fail silently. |
| 4 | minor | `README.md` (uncommitted) | Logo changed from centered `<img width="320">` to inline `![logo]` — decide before merge. |
| 5 | minor | `gleam run -m go_over` | `--outdated` flag deprecated in favor of `gleam deps outdated`. |
| 6 | minor | `test/util_test.gleam:19-21` | Duplicate assertion `parse_always_init("basic.toml")` twice. |

---

## Nits

- `ActionFailedErr` on `main` had no index/total; revamp adds `2/5` style messages — good improvement, now tested in `util_err_test.gleam`.
- `help` no longer accepts raw `--help` in `cactus.gleam` case — correctly delegated to `cli.gleam` parser.
- `package.json` version aligned to `1.4.0` (was `0.1.0` on main).

---

## Breaking changes (for release notes)

### Config schema (new in 1.4.0)

| Field | Level | Default | Values |
|-------|-------|---------|--------|
| `files_scope` | hook + action | `all` | `staged`, `all`, `unstaged` |
| `on_failure` | hook | `stop` | `stop`, `continue` |
| `skip_if` | hook + action | none | `"ci"` only |
| `skip_env` | action | none | `NAME=value` |
| `env` | action | `{}` | inline string table |
| `cwd` | action | `.` | any path |
| `kind` | action | `module` | `module`, `sub_command`, `binary` |

### CLI

| Change | Notes |
|--------|-------|
| `clean` command | Removes only hooks containing ` -m cactus -- ` marker |
| `--verbose` | Per-action skip/run logging |
| `--dry-run` | Print actions without executing |
| `--config <path>` | Alternate `gleam.toml` location |

### Hook scripts

Generated scripts embed compile target and JS runtime. **Users must re-run `init`** after changing `--target` or `--runtime`.

### Dependencies

| Package | main | revamp |
|---------|------|--------|
| `gleam_stdlib` | `>= 0.34` | `>= 1.0` (requires Gleam 1.x) |
| `envoy` | — | new (CI/skip_env) |
| `go_over` | 3.x | 4.x RC |

### Toolchain

Gleam 1.15 → 1.17, Erlang 28 → 29, Node 22 → 24 (`.tool-versions`, CI).

### Bug fix vs main

`always_init` on hook run now uses `windows_hooks()` instead of hardcoded `False` — correct for Windows users.

---

## Module review notes

### `run.gleam`

- TOML parsing is thorough with clear `InvalidFieldErr` paths.
- `files_scope` inheritance from hook → action works via `hook_default` parameter.
- `on_failure = "continue"` correctly collects first error and fails at end — **untested at runtime**.
- Pre-commit `run_with_stash` flow is logically sound when stash/pop succeed.
- `do_run` uses `action.cwd` for both file scope queries and command execution — correct for monorepo subdir actions.

### `git.gleam`

- Stash message `cactus-pre-commit` is constant and tested.
- `no_changes_to_stash` handles git's "No local changes to save" gracefully.
- Pop conflict appends helpful recovery instructions.

### `modified.gleam`

- `FilesScope` git commands match README table.
- Path normalization handles `./` prefix and Windows backslashes.
- Glob supports `**/` prefix and single `*` wildcards per segment.

### `write.gleam`

- `is_cactus_hook` marker prevents `clean` from deleting user hooks.
- Hook name whitelist blocks path traversal in hook filenames.
- Dual `@target` templates correctly embed runtime at compile time.

### `cli.gleam` + `cactus.gleam`

- Last positional argument wins as command — flags must precede command.
- `CLIErr` vs `ActionFailedErr` produce different exit messages (tested for formatting).
- `get_package_version` reads from resolved config path.

### `util.gleam`

- Error types cover all failure modes; `err_as_str` tested.

---

## Test coverage audit

### Well covered

- CLI flag parsing, config path resolution
- TOML action parsing (kinds, missing fields, invalid types)
- File pattern matching (extensions, paths, basic globs)
- Git file scopes with temp repos
- Stash push/pop (clean, unstaged, untracked)
- Hook init/clean/template generation
- Dry-run execution
- `merge_stash_pop_result` precedence
- E2E via `target_test.sh`

### Gaps (non-blocking)

| Area | Risk |
|------|------|
| `skip_if` / `skip_env` runtime | Fixture exists but no assertion test; invalid hook names block CLI testing |
| `on_failure = "continue"` | Parsed, never executed in tests |
| `env` on actions | `SetEnvironment` path untested |
| `cwd` on actions | Subdir git scope untested |
| Real `ActionFailedErr` from `run.run` | No integration test |
| Pre-commit E2E with stash + actions | Partial (unit stash tests only) |
| `main()` dispatch | No direct tests for `clean`, `init`, hook run |
| Glob edge cases (multiple `*`) | Not tested |

---

## Documentation review

| Item | Status |
|------|--------|
| Config examples match parser | Mostly yes; `skip_if` CI semantics differ |
| `files` filter description | **Contradicts implementation** (see major #1) |
| Stash behavior section | **Partially inaccurate** (see major #3) |
| Troubleshooting table | Accurate for verbose/dry-run/config paths |
| Windows section | Accurate (Git Bash required) |
| Supported hooks list | Matches `write.valid_hooks` |
| Self-dogfooding `gleam.toml` | `files_scope = "staged"` on pre-commit — good practice |

---

## Automated review

### Bugbot (natural language diff)

| Severity | Location | Finding |
|----------|----------|---------|
| high | `modified.gleam:152-156` | Empty scope runs filtered actions |
| high | `git.gleam:70-88` | Stash restore silently skipped |
| medium | `run.gleam:252-257` | `skip_if` treats `CI=false` as CI |
| medium | `run.gleam:455-463` | Pop error hidden on hook failure |

### Security review (branch diff vs main)

**No medium, high, or critical findings.** Subprocess uses argv arrays (no shell injection). Hook names are whitelisted. `env`/`cwd` from config are intentional project-owner capabilities within the git-hooks trust model.

---

## Suggested pre-merge checklist

1. Fix or document `modified_files_match` empty-list behavior
2. Fix `skip_if = "ci"` to match README (`CI=true` only)
3. Fix or rewrite README stash/unrelated-stash section
4. Add `CHANGELOG.md` with 1.4.0 migration notes (or remove broken link)
5. Consider error when cactus stash cannot be popped after successful stash
6. Add runtime tests for `skip_if`, `on_failure`, and `env`
7. Resolve README logo markup (centered vs inline)
8. Re-run full CI matrix on merge to `main` (Bun, Deno, Windows)
