import filepath
import git_gleam_hooks/run
import git_gleam_hooks/write.{valid_hooks}
import gleam/list
import shellout
import simplifile

fn toml_path() {
  let assert Ok(pwd) = simplifile.current_directory()
  filepath.join(pwd, "gleam.toml")
}

pub fn main() {
  let gleam_toml = toml_path()
  case shellout.arguments() {
    [] | ["init"] -> {
      write.init(gleam_toml)
      Nil
    }

    [arg] -> {
      case list.contains(valid_hooks, arg) {
        True -> {
          run.run(gleam_toml, arg)
          Nil
        }
        False -> todo
      }
    }

    _ -> todo
  }
}
