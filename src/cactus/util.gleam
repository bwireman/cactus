import cactus/errors.{InvalidTomlErr, as_err, as_fs_err}
import filepath
import gleam/result
import simplifile
import tom

pub fn parse_gleam_toml(path: String) {
  use body <- result.try(as_fs_err(simplifile.read(path), path))
  tom.parse(body) |> as_err(InvalidTomlErr)
}

pub fn gleam_toml_path() {
  let assert Ok(pwd) = simplifile.current_directory()
  filepath.join(pwd, "gleam.toml")
}
