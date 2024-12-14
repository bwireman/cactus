import cactus/util
import gleam/result
import gleam/string
import shellout

pub fn list_files(args: List(String)) -> Result(List(String), util.CactusErr) {
  shellout.command(run: "git", with: args, in: ".", opt: [])
  |> result.map(string.split(_, "\n"))
  |> result.map(util.drop_empty)
  |> util.as_git_error()
}

pub fn stash_unstaged() -> Result(String, util.CactusErr) {
  shellout.command(
    run: "git",
    with: ["stash", "push", "--keep-index", "--include-untracked"],
    in: ".",
    opt: [],
  )
  |> util.as_git_error()
}

pub fn pop_stash() -> Result(String, util.CactusErr) {
  shellout.command(run: "git", with: ["stash", "pop"], in: ".", opt: [])
  |> util.as_git_error()
}
