import cactus/util
import gleam/list
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

fn stash_count_in(dir: String) -> Result(Int, util.CactusErr) {
  list_files_in(dir, ["stash", "list"])
  |> result.map(list.length)
}

pub fn stash_list_length(dir: String) -> Result(Int, util.CactusErr) {
  stash_count_in(dir)
}

pub fn no_changes_to_stash(
  err: util.CactusErr,
) -> Result(Bool, util.CactusErr) {
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
  use before <- result.try(stash_count_in(dir))

  case
    run_command_in(dir, ["stash", "push", "--keep-index", "--include-untracked"])
  {
    Ok(_) -> {
      use after <- result.try(stash_count_in(dir))
      Ok(after > before)
    }

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
