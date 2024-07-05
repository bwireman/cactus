import gleam/result.{replace_error}
import gleam/string
import simplifile.{type FileError, describe_error}
import tom.{type GetError, NotFound, WrongType}

pub type CactusErr {
  InvalidFieldErr(err: GetError)
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
      "Missing field in config: '" <> string.join(keys, ".") <> "'"
    InvalidFieldErr(WrongType(keys, expected, got)) ->
      "Invalid field in config: '"
      <> string.join(keys, ".")
      <> "' expected: '"
      <> expected
      <> "' got '"
      <> got
      <> "'"
    InvalidTomlErr -> "InvalidTomlErr"
    ActionFailedErr(output) -> "ActionFailedErr:\n" <> output
    FSErr(path, err) -> "FSErr at " <> path <> " with " <> describe_error(err)
    CLIErr(arg) -> "CLIErr: invalid arg '" <> arg <> "'"
    None -> panic as "how?"
  }
}
