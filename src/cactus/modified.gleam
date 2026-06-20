import cactus/git
import cactus/util.{type CactusErr, InvalidFieldErr, drop_empty, quote}
import gleam/list
import gleam/result.{try}
import gleam/string
import gleither.{Right}

pub type FilesScope {
  Staged
  All
  Unstaged
}

pub fn default_files_scope() -> FilesScope {
  All
}

pub fn parse_files_scope(raw: String) -> Result(FilesScope, CactusErr) {
  case string.lowercase(string.trim(raw)) {
    "staged" -> Ok(Staged)
    "all" -> Ok(All)
    "unstaged" -> Ok(Unstaged)
    _ ->
      Error(InvalidFieldErr(
        "files_scope",
        Right(
          "got: "
          <> quote(raw)
          <> " expected: one of ['staged', 'all', or 'unstaged']",
        ),
      ))
  }
}

pub fn files_scope_label(scope: FilesScope) -> String {
  case scope {
    Staged -> "staged"
    All -> "all"
    Unstaged -> "unstaged"
  }
}

pub fn get_files_for_scope(
  scope: FilesScope,
) -> Result(List(String), CactusErr) {
  get_files_for_scope_in(".", scope)
}

pub fn get_files_for_scope_in(
  dir: String,
  scope: FilesScope,
) -> Result(List(String), CactusErr) {
  case scope {
    Staged -> git.list_files_in(dir, ["diff", "--cached", "--name-only"])
    Unstaged -> {
      use tracked <- try(git.list_files_in(dir, ["diff", "--name-only"]))
      use untracked <- try(
        git.list_files_in(dir, ["ls-files", "--others", "--exclude-standard"]),
      )
      Ok(list.unique(list.append(tracked, untracked)))
    }
    All -> {
      use staged <- try(
        git.list_files_in(dir, ["diff", "--cached", "--name-only"]),
      )
      use tracked <- try(git.list_files_in(dir, ["diff", "--name-only"]))
      use untracked <- try(
        git.list_files_in(dir, ["ls-files", "--others", "--exclude-standard"]),
      )
      Ok(list.unique(list.append(staged, list.append(tracked, untracked))))
    }
  }
}

fn normalize_path(path: String) -> String {
  let path = case string.starts_with(path, "./") {
    True -> string.drop_start(path, 2)
    False -> path
  }
  path |> string.replace("\\", "/") |> string.trim
}

pub fn filter_files_under_cwd(
  files: List(String),
  cwd: String,
) -> List(String) {
  case normalize_path(cwd) {
    "." | "" -> files
    prefix ->
      list.filter(files, fn(file) {
        let file = normalize_path(file)
        file == prefix || string.starts_with(file, prefix <> "/")
      })
  }
}

pub fn file_matches_pattern(file: String, pattern: String) -> Bool {
  let file = normalize_path(file)
  let pattern = normalize_path(pattern)

  case pattern {
    "" -> False
    _ ->
      case string.contains(pattern, "*") {
        True -> simple_glob_match(file, pattern)
        False ->
          case string.starts_with(pattern, ".") {
            True -> string.ends_with(file, pattern)
            False -> file == pattern
          }
      }
  }
}

fn simple_glob_match(file: String, pattern: String) -> Bool {
  case string.split_once(pattern, on: "**/") {
    Ok(#(prefix, suffix)) ->
      string.starts_with(file, prefix)
      && wildcard_match(file_name(file), suffix)
    Error(_) ->
      case string.split(pattern, "/") {
        [segment] -> wildcard_match(file_name(file), segment)
        segments -> match_segments_loop(file, segments)
      }
  }
}

fn file_name(path: String) -> String {
  case list.last(string.split(path, "/")) {
    Ok(name) -> name
    Error(_) -> path
  }
}

fn wildcard_match(text: String, pattern: String) -> Bool {
  case string.split(pattern, "*") {
    [whole] -> text == whole
    [prefix, suffix] ->
      case prefix {
        "" -> string.ends_with(text, suffix)
        _ -> string.starts_with(text, prefix) && string.ends_with(text, suffix)
      }
    _ -> False
  }
}

fn match_segments_loop(file: String, segments: List(String)) -> Bool {
  case segments {
    [] -> file == ""
    [segment, ..rest] ->
      case string.split_once(file, "/") {
        Ok(#(head, tail)) ->
          wildcard_match(head, segment) && match_segments_loop(tail, rest)
        Error(_) -> wildcard_match(file, segment) && rest == []
      }
  }
}

pub fn modified_files_match(
  modified_files: List(String),
  watched: List(String),
) {
  let modified_files = drop_empty(modified_files)
  let watched = drop_empty(watched)

  list.is_empty(watched)
  || list.any(watched, fn(pattern) {
    list.any(modified_files, fn(file) { file_matches_pattern(file, pattern) })
  })
}
