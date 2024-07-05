import filepath
import gleam/result
import simplifile
import tom

pub fn parse_gleam_toml(path: String) {
  use body <- result.try(simplifile.read(path) |> result.nil_error)
  tom.parse(body) |> result.nil_error
}

pub fn gleam_toml_path() {
  let assert Ok(pwd) = simplifile.current_directory()
  filepath.join(pwd, "gleam.toml")
}
