import cactus/util
import gleam/list
import gleam/result
import gleam/string
import shellout

pub const stash_message = "cactus-pre-commit"

fn full_command(args: List(String)) -> String {
  string.join(["git", ..args], " ")
}

pub fn run_command_in(
  dir: String,
  args: List(String),
) -> Result(String, util.CactusErr) {
  shellout.command(run: "git", with: args, in: dir, opt: [])
  |> util.as_git_error(full_command(args))
}

pub fn list_files_in(
  dir: String,
  args: List(String),
) -> Result(List(String), util.CactusErr) {
  shellout.command(run: "git", with: args, in: dir, opt: [])
  |> result.map(string.split(_, "\n"))
  |> result.map(list.map(_, string.trim))
  |> result.map(util.drop_empty)
  |> util.as_git_error(full_command(args))
}

pub fn list_files(args: List(String)) -> Result(List(String), util.CactusErr) {
  list_files_in(".", args)
}

fn stash_push_created_stash(output: String) -> Bool {
  !string.contains(output, "No local changes to save")
}

fn no_changes_to_stash(err: util.CactusErr) -> Result(Bool, util.CactusErr) {
  case err {
    util.GitError(command, output) ->
      case stash_push_created_stash(output) {
        True -> Error(util.GitError(command, output))
        False -> Ok(False)
      }

    _ -> Error(err)
  }
}

fn has_stash_ref_in(dir: String) -> Bool {
  case run_command_in(dir, ["rev-parse", "-q", "--verify", "refs/stash"]) {
    Ok(_) -> True
    Error(_) -> False
  }
}

pub fn stash_unstaged_in(dir: String) -> Result(Bool, util.CactusErr) {
  case has_stash_ref_in(dir) {
    True -> Ok(False)
    False ->
      case
        run_command_in(dir, [
          "stash", "push", "--keep-index", "--include-untracked", "-m",
          stash_message,
        ])
      {
        Ok(output) -> Ok(stash_push_created_stash(output))
        Error(err) -> no_changes_to_stash(err)
      }
  }
}

pub fn stash_unstaged() -> Result(Bool, util.CactusErr) {
  stash_unstaged_in(".")
}

pub fn worktree_has_unstaged_changes_in(
  dir: String,
) -> Result(Bool, util.CactusErr) {
  case list_files_in(dir, ["diff", "--name-only"]) {
    Ok(tracked) ->
      case list_files_in(dir, ["ls-files", "--others", "--exclude-standard"]) {
        Ok(untracked) ->
          Ok(!list.is_empty(tracked) || !list.is_empty(untracked))
        Error(err) -> Error(err)
      }
    Error(err) -> Error(err)
  }
}

pub fn worktree_has_unstaged_changes() -> Result(Bool, util.CactusErr) {
  worktree_has_unstaged_changes_in(".")
}

pub fn pop_stash_required_in(dir: String) -> Result(String, util.CactusErr) {
  case run_command_in(dir, ["stash", "list", "-1", "--format=%gs"]) {
    Ok(message) ->
      case string.contains(string.trim(message), stash_message) {
        True ->
          case run_command_in(dir, ["stash", "pop"]) {
            Ok(output) -> Ok(output)
            Error(util.GitError(command, output)) ->
              Error(util.GitError(
                command,
                output
                  <> "\n\nResolve conflicts, then run `git stash list` and "
                  <> "`git stash drop` if the cactus-pre-commit entry remains.",
              ))
            Error(err) -> Error(err)
          }
        False ->
          Error(util.GitError(
            "git stash pop",
            "Expected cactus-pre-commit stash at top but found: "
              <> util.quote(string.trim(message))
              <> ". Run `git stash list` to recover your changes.",
          ))
      }
    Error(_) ->
      Error(util.GitError(
        "git stash list",
        "No cactus-pre-commit stash found to restore.",
      ))
  }
}

pub fn pop_stash_required() -> Result(String, util.CactusErr) {
  pop_stash_required_in(".")
}
