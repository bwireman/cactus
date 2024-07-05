import cactus/errors.{FSErr, as_err}
import filepath
import gleam/result
import simplifile
import tom

pub fn parse_gleam_toml(path: String) {
  use body <- result.try(simplifile.read(path) |> as_err(FSErr))
  tom.parse(body) |> as_err(FSErr)
}

pub fn gleam_toml_path() {
  let assert Ok(pwd) = simplifile.current_directory()
  filepath.join(pwd, "gleam.toml")
}
