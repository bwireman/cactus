import cactus/util
import gleam/result
import gleam/string
import shellout

fn full_command(args: List(String)) -> String {
  string.join(["git", ..args], " ")
}

fn run_command(args: List(String)) -> Result(String, util.CactusErr) {
  shellout.command(run: "git", with: args, in: ".", opt: [])
  |> util.as_git_error(full_command(args))
}

pub fn list_files(args: List(String)) -> Result(List(String), util.CactusErr) {
  shellout.command(run: "git", with: args, in: ".", opt: [])
  |> result.map(string.split(_, "\n"))
  |> result.map(util.drop_empty)
  |> util.as_git_error(full_command(args))
}

pub fn stash_unstaged() -> Result(String, util.CactusErr) {
  run_command(["stash", "push", "--keep-index", "--include-untracked"])
}

pub fn pop_stash() -> Result(String, util.CactusErr) {
  run_command(["stash", "pop"])
}
