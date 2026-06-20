import envoy
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/result.{replace_error}
import gleam/string
import gleither.{type Either, Left, Right}
import gxyz/list.{reject}
import shellout
import simplifile.{type FileError, describe_error}
import tom.{type GetError, type Toml, NotFound, WrongType}

pub const cactus = "cactus"

pub type CactusErr {
  InvalidFieldErr(field: String, err: Either(GetError, String))
  InvalidTomlErr
  ActionFailedErr(index: Int, total: Int, command: String, output: String)
  FSErr(path: String, err: FileError)
  CLIErr(arg: String)
  GitError(command: String, err: String)
  NoErr
}

pub fn as_err(res: Result(a, b), err: CactusErr) -> Result(a, CactusErr) {
  replace_error(res, err)
}

pub fn as_invalid_field_err(res: Result(a, GetError)) -> Result(a, CactusErr) {
  case res {
    Ok(_) -> as_err(res, NoErr)
    Error(get_error) -> as_err(res, InvalidFieldErr("", Left(get_error)))
  }
}

pub fn as_git_error(
  res: Result(a, #(Int, String)),
  command: String,
) -> Result(a, CactusErr) {
  case res {
    Ok(_) -> as_err(res, NoErr)
    Error(#(_, output)) -> as_err(res, GitError(command, output))
  }
}

pub fn as_fs_err(
  res: Result(a, FileError),
  path: String,
) -> Result(a, CactusErr) {
  case res {
    Ok(_) -> as_err(res, NoErr)
    Error(file_error) -> as_err(res, FSErr(path, file_error))
  }
}

pub fn err_as_str(err: CactusErr) -> String {
  case err {
    InvalidFieldErr(_, Left(NotFound(keys))) ->
      "Missing field in config: " <> quote(string.join(keys, "."))

    InvalidFieldErr(_, Left(WrongType(keys, expected, got))) ->
      join_text([
        "Invalid field in config:",
        quote(string.join(keys, ".")),
        "expected:",
        quote(expected),
        "got:",
        quote(got),
      ])

    InvalidFieldErr("", Right(err)) -> "Invalid field in config: " <> err

    InvalidFieldErr(field, Right(err)) ->
      join_text(["Invalid field in config:", field, err])

    InvalidTomlErr -> "Invalid Toml Error"

    ActionFailedErr(index, total, command, output) ->
      join_text([
        "Action",
        int.to_string(index) <> "/" <> int.to_string(total),
        "failed:",
        quote(command),
      ])
      <> "\n"
      <> output

    FSErr(path, err) ->
      join_text(["FS Error at", path, "with", describe_error(err)])

    CLIErr(arg) -> "CLI Error: invalid arg " <> quote(arg)

    GitError(command, err) ->
      "Error while running " <> quote(command) <> " : " <> quote(err)

    NoErr -> panic as "how?"
  }
}

pub fn drop_empty(l: List(String)) -> List(String) {
  reject(l, string.is_empty)
}

pub fn is_truthy_ci() -> Bool {
  case envoy.get("CI") {
    Ok(value) ->
      case string.lowercase(string.trim(value)) {
        "true" | "1" -> True
        _ -> False
      }
    Error(_) -> False
  }
}

pub fn quote(str: String) -> String {
  "'" <> str <> "'"
}

pub fn normalize_newlines(text: String) -> String {
  string.replace(text, "\r\n", "\n")
}

pub fn parse_gleam_toml(path: String) -> Result(Dict(String, Toml), CactusErr) {
  use body <- result.try(as_fs_err(simplifile.read(path), path))
  body
  |> normalize_newlines
  |> tom.parse()
  |> as_err(InvalidTomlErr)
}

pub fn parse_always_init(path: String) {
  parse_gleam_toml(path)
  |> result.try(fn(t) {
    t
    |> tom.get_bool(["cactus", "always_init"])
    |> as_invalid_field_err
  })
  |> result.unwrap(False)
}

pub fn get_package_version(path: String) -> Result(String, CactusErr) {
  use manifest <- result.try(parse_gleam_toml(path))
  tom.get_string(manifest, ["version"]) |> as_invalid_field_err
}

pub fn join_text(text: List(String)) -> String {
  string.join(text, " ")
}

pub fn print_progress(msg: String) {
  shellout.style(msg, with: shellout.color(["brightmagenta"]), custom: [])
  |> io.println()
}

pub fn print_warning(msg: String) {
  shellout.style(msg <> "\n", with: shellout.color(["red"]), custom: [])
  |> io.println()
}

pub fn format_success(msg: String) -> String {
  shellout.style(msg, with: shellout.color(["brightgreen"]), custom: [])
}

pub fn print_success(msg: String) {
  format_success(msg <> "\n")
  |> io.println()
}

pub fn format_info(msg: String) {
  shellout.style(msg, with: shellout.color(["yellow"]), custom: [])
}

pub fn print_info(msg: String) {
  format_info(msg <> "\n")
  |> io.println()
}

pub fn print_verbose(enabled: Bool, msg: String) {
  case enabled {
    True -> print_info(msg)
    False -> Nil
  }
}
