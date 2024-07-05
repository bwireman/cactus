import gleam/result.{replace_error}

pub type CactusErr {
  MissingField(field: String)
  InvalidToml
  ActionFailed
  FSErr
  CLIErr
}

pub fn as_err(res: Result(a, b), err: CactusErr) -> Result(a, CactusErr) {
  replace_error(res, err)
}

pub fn str(err: CactusErr) -> String {
  case err {
    MissingField(field) -> "Missing Field in config: '" <> field <> "'"
    InvalidToml -> "InvalidToml"
    ActionFailed -> "ActionFailed"
    FSErr -> "FSErr"
    CLIErr -> "CLIErr"
  }
}
