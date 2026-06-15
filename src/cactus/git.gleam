import cactus/util
import gleam/result
import gleam/string
import shellout

fn full_command(args: List(String)) -> String {
  string.join(["git", ..args], " ")
}

fn run_command_in(
  dir: String,
  args: List(String),
) -> Result(String, util.CactusErr) {
  shellout.command(run: "git", with: args, in: dir, opt: [])
  |> util.as_git_error(full_command(args))
}

fn list_files_in(
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
    run_command_in(dir, ["stash", "push", "--keep-index", "--include-untracked"])
  {
    Ok(output) -> Ok(!string.contains(output, "No local changes to save"))

    Error(err) -> no_changes_to_stash(err)
  }
}

pub fn stash_unstaged() -> Result(Bool, util.CactusErr) {
  stash_unstaged_in(".")
}

pub fn pop_stash_in(dir: String) -> Result(String, util.CactusErr) {
  run_command_in(dir, ["stash", "pop"])
}

pub fn pop_stash() -> Result(String, util.CactusErr) {
  pop_stash_in(".")
}
