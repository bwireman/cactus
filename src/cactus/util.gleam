import gleam/dict.{type Dict}
import gleam/result.{replace_error}
import gleam/string
import simplifile.{type FileError, describe_error}
import tom.{type GetError, type Toml, NotFound, WrongType}

pub type CactusErr {
  InvalidFieldErr(err: GetError)
  InvalidFieldCustomErr(field: String)
  InvalidTomlErr
  ActionFailedErr(output: String)
  FSErr(path: String, err: FileError)
  CLIErr(arg: String)
  None
}

pub fn as_err(res: Result(a, b), err: CactusErr) -> Result(a, CactusErr) {
  replace_error(res, err)
}

pub fn as_invalid_field_err(res: Result(a, GetError)) -> Result(a, CactusErr) {
  case res {
    Ok(_) -> as_err(res, None)
    Error(get_error) -> as_err(res, InvalidFieldErr(get_error))
  }
}

pub fn as_fs_err(
  res: Result(a, FileError),
  path: String,
) -> Result(a, CactusErr) {
  case res {
    Ok(_) -> as_err(res, None)
    Error(file_error) -> as_err(res, FSErr(path, file_error))
  }
}

pub fn str(err: CactusErr) -> String {
  case err {
    InvalidFieldErr(NotFound(keys)) ->
      "Missing field in config: " <> quote(string.join(keys, "."))
    InvalidFieldErr(WrongType(keys, expected, got)) ->
      "Invalid field in config: "
      <> quote(string.join(keys, "."))
      <> " expected: "
      <> quote(expected)
      <> " got "
      <> quote(got)
    InvalidFieldCustomErr(field) -> "Invalid field in config: " <> field
    InvalidTomlErr -> "Invalid Toml Error"
    ActionFailedErr(output) -> "Action Failed Error:\n" <> output
    FSErr(path, err) ->
      "FS Error at " <> path <> " with " <> describe_error(err)
    CLIErr(arg) -> "CLI Error: invalid arg " <> quote(arg)
    None -> panic as "how?"
  }
}

pub const cactus = "cactus"

pub fn quote(str: String) -> String {
  "'" <> str <> "'"
}

pub fn parse_gleam_toml(path: String) -> Result(Dict(String, Toml), CactusErr) {
  use body <- result.try(as_fs_err(simplifile.read(path), path))
  tom.parse(body) |> as_err(InvalidTomlErr)
}
