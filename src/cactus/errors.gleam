import gleam/result.{replace_error}
import simplifile.{type FileError, describe_error}

pub type CactusErr {
  None
  MissingFieldErr(field: String)
  InvalidTomlErr
  ActionFailedErr(output: String)
  FSErr(path: String, err: FileError)
  CLIErr(arg: String)
}

pub fn as_err(res: Result(a, b), err: CactusErr) -> Result(a, CactusErr) {
  replace_error(res, err)
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
    MissingFieldErr(field) -> "Missing field in config: '" <> field <> "'"
    InvalidTomlErr -> "InvalidTomlErr"
    ActionFailedErr(output) -> "ActionFailedErr:\n" <> output
    FSErr(path, err) -> "FSErr at " <> path <> " with " <> describe_error(err)
    CLIErr(arg) -> "CLIErr: invalid arg '" <> arg <> "'"
    None -> panic as "how?"
  }
}
