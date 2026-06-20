# Changelog

All notable changes to this project will be documented in this file.

## 1.4.1

### Added

- Warning when pre-commit/pre-merge-commit cannot stash because a git stash
  already exists and the working tree is still dirty

### Changed

- `pre-merge-commit` uses the same stash/pop behavior as `pre-commit`
- File filters respect `cwd`: only paths under the action's `cwd` are considered
- **`skip_if` removed** — use `skip_env` instead (e.g. `skip_env = "CI=true"`)
- `skip_env` supported at hook and action level; values may contain `=` (parsed
  via first `=`)

### Removed

- `skip_if` — replaced by `skip_env` for all skip conditions

### Fixed

- `always_init` re-init errors are no longer swallowed during hook runs
- Invalid `always_init` type surfaces a config error instead of defaulting to
  `false`
- Carriage returns stripped from git file list output (Windows compatibility)
- Hook script creation tolerates existing `.git/hooks` directory or hook file

## 1.4.0

### Added

- `files_scope` at hook and action level (`staged`, `all`, `unstaged`)
- `on_failure` hook option (`stop` or `continue`)
- `skip_if = "ci"` (skips when `CI=true` or `CI=1`)
- `skip_env` per action (`NAME=value`)
- `env` inline table per action
- `cwd` per action
- CLI: `clean`, `--verbose`, `--dry-run`, `--config`
- Pre-commit stash/pop with `cactus-pre-commit` tag

### Changed

- Requires Gleam 1.x (`gleam_stdlib >= 1.0`)
- Hook scripts embed compile target and JS runtime — re-run `init` after
  changing target/runtime
- `always_init` on hook run respects Windows platform for hook templates
- File-filtered actions skip when no files in scope match watched patterns
- Pre-commit does not stash when unrelated stashes already exist on the stack

### Fixed

- `skip_if = "ci"` no longer treats `CI=false` as a CI environment
- Pre-commit reports an error when cactus stash cannot be restored after a
  successful stash
- Stash pop failures take precedence over hook action failures when both occur

### Glob limitations

Glob matching supports:

- Extension suffixes (e.g. `.gleam`)
- Exact paths
- Simple globs with `*` and `**/` (e.g. `src/**/*.gleam`, `*.gleam`)

Not supported:

- Multiple `*` wildcards in a single path segment (e.g. `*.*.gleam`)
- Full POSIX glob semantics

## 1.3.5

Previous stable release on `main`.
