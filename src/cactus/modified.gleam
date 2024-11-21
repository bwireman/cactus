import cactus/util
import gleam/list
import gleam/result.{try}
import gleam/string
import shellout

fn list_files(args: List(String)) -> Result(List(String), util.CactusErr) {
  shellout.command(run: "git", with: args, in: ".", opt: [])
  |> result.map(string.split(_, "\n"))
  |> result.map(util.drop_empty)
  |> util.as_git_error()
}

pub fn get_modified_files() -> Result(List(String), util.CactusErr) {
  use modified <- try(
    list_files(["ls-files", "--exclude-standard", "--others"]),
  )
  use untracked <- try(list_files(["diff", "--name-only", "HEAD"]))

  Ok(list.append(untracked, modified))
}

pub fn modified_files_match(modified_files: List(String), watched: List(String)) {
  let modified_files = util.drop_empty(modified_files)
  let watched = util.drop_empty(watched)

  list.is_empty(modified_files)
  || list.is_empty(watched)
  || {
    let endings = list.filter(watched, string.starts_with(_, "."))
    list.any(modified_files, matches_ending(_, endings))
  }
  || {
    list.filter(watched, string.starts_with(_, "./"))
    |> list.map(string.drop_start(_, 2))
    |> list.append(watched)
    |> list.unique()
    |> list.any(list.contains(modified_files, _))
  }
}

pub fn matches_ending(modified: String, endings: List(String)) {
  list.any(endings, fn(end) { string.ends_with(modified, end) })
}
