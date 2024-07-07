import gleam/dict.{type Dict}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result.{replace_error}
import gleam/string
import gleither.{type Either, Left, Right}
import shellout
import simplifile.{type FileError, describe_error}
import tom.{type GetError, type Toml, NotFound, WrongType}

pub const cactus = "cactus"

pub type CactusErr {
  InvalidFieldErr(field: Option(String), err: Either(GetError, String))
  InvalidTomlErr
  ActionFailedErr(output: String)
  FSErr(path: String, err: FileError)
  CLIErr(arg: String)
  NoErr
}

pub fn as_err(res: Result(a, b), err: CactusErr) -> Result(a, CactusErr) {
  replace_error(res, err)
}

pub fn as_invalid_field_err(res: Result(a, GetError)) -> Result(a, CactusErr) {
  case res {
    Ok(_) -> as_err(res, NoErr)
    Error(get_error) -> as_err(res, InvalidFieldErr(None, Left(get_error)))
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

    InvalidFieldErr(Some(field), Right(err)) ->
      join_text(["Invalid field in config:", field, err])

    InvalidFieldErr(None, Right(err)) -> "Invalid field in config: " <> err

    InvalidTomlErr -> "Invalid Toml Error"

    ActionFailedErr(output) -> "Action Failed Error:\n" <> output

    FSErr(path, err) ->
      join_text(["FS Error at", path, "with", describe_error(err)])

    CLIErr(arg) -> "CLI Error: invalid arg " <> quote(arg)

    NoErr -> panic as "how?"
  }
}

pub fn quote(str: String) -> String {
  "'" <> str <> "'"
}

pub fn parse_gleam_toml(path: String) -> Result(Dict(String, Toml), CactusErr) {
  use body <- result.try(as_fs_err(simplifile.read(path), path))
  tom.parse(body) |> as_err(InvalidTomlErr)
}

pub fn join_text(text: List(String)) -> String {
  string.join(text, " ")
}

pub fn print_progress(msg: String) {
  shellout.style(msg, with: shellout.color(["brightmagenta"]), custom: [])
  |> io.println
}

pub fn print_warning(msg: String) {
  shellout.style(msg <> "\n", with: shellout.color(["red"]), custom: [])
  |> io.println
}
