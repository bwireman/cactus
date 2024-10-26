import cactus/util
import gleam/list
import gleam/result
import gleam/string
import shellout

pub fn get_modified_files() -> Result(List(String), util.CactusErr) {
  shellout.command(
    run: "git",
    with: ["diff", "--name-only", "HEAD"],
    in: ".",
    opt: [],
  )
  |> result.map(string.split(_, "\n"))
  |> result.map(util.drop_empty)
  |> util.as_git_error()
}

pub fn modfied_files_match(modfied_files: List(String), watched: List(String)) {
  let modfied_files = util.drop_empty(modfied_files) |> list.unique
  let watched = util.drop_empty(watched) |> list.unique

  case modfied_files == [] || watched == [] {
    False -> {
      let endings = list.filter(watched, string.starts_with(_, "."))

      let cleaned =
        list.append(
          watched,
          watched
            |> list.filter(string.starts_with(_, "./"))
            |> list.map(string.drop_left(_, 2)),
        )
        |> list.unique()

      list.any(cleaned, list.contains(modfied_files, _))
      || list.any(modfied_files, matches_ending(_, endings))
    }

    _ -> True
  }
}

pub fn matches_ending(modified: String, endings: List(String)) {
  list.any(endings, fn(end) { string.ends_with(modified, end) })
}
