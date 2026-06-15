import cactus/util
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
  |> result.map(util.drop_empty)
  |> util.as_git_error(full_command(args))
}

pub fn list_files(args: List(String)) -> Result(List(String), util.CactusErr) {
  list_files_in(".", args)
}

fn no_changes_to_stash(err: util.CactusErr) -> Result(Bool, util.CactusErr) {
  case err {
    util.GitError(command, output) ->
      case string.contains(output, "No local changes to save") {
        True -> Ok(False)
        False -> Error(util.GitError(command, output))
      }

    _ -> Error(err)
  }
}

pub fn stash_unstaged_in(dir: String) -> Result(Bool, util.CactusErr) {
  case
    run_command_in(dir, [
      "stash", "push", "--keep-index", "--include-untracked", "-m",
      stash_message,
    ])
  {
    Ok(output) -> Ok(!string.contains(output, "No local changes to save"))
    Error(err) -> no_changes_to_stash(err)
  }
}

pub fn stash_unstaged() -> Result(Bool, util.CactusErr) {
  stash_unstaged_in(".")
}

pub fn pop_stash_in(dir: String) -> Result(String, util.CactusErr) {
  pop_cactus_stash_in(dir)
}

pub fn pop_stash() -> Result(String, util.CactusErr) {
  pop_cactus_stash_in(".")
}

pub fn pop_cactus_stash_in(dir: String) -> Result(String, util.CactusErr) {
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
        False -> Ok("")
      }
    Error(_) -> Ok("")
  }
}
