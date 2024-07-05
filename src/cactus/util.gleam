import cactus/errors.{type CactusErr, InvalidTomlErr, as_err, as_fs_err}
import gleam/dict.{type Dict}
import gleam/result
import simplifile
import tom.{type Toml}

pub fn parse_gleam_toml(path: String) -> Result(Dict(String, Toml), CactusErr) {
  use body <- result.try(as_fs_err(simplifile.read(path), path))
  tom.parse(body) |> as_err(InvalidTomlErr)
}
