import cactus/run
import cactus/util
import cactus/write.{valid_hooks}
import filepath
import gleam/io
import gleam/list
import gleam/result.{replace}
import gleam/string
import shellout
import simplifile

pub fn main() {
  let gleam_toml = util.gleam_toml_path()
  let assert Ok(pwd) = simplifile.current_directory()
  let hooks_dir =
    pwd
    |> filepath.join(".git")
    |> filepath.join("hooks")

  let cmd =
    shellout.arguments()
    |> list.filter(fn(a) { !string.ends_with(a, ".js") })
    |> list.filter(fn(a) { !string.ends_with(a, ".mjs") })
    |> list.filter(fn(a) { !string.ends_with(a, ".cjs") })
    |> list.last()
    |> result.unwrap("")

  let res = case cmd {
    "" | "init" -> {
      write.init(hooks_dir, gleam_toml)
    }

    arg -> {
      case list.contains(valid_hooks, arg) {
        True -> {
          run.run(gleam_toml, arg)
          |> replace([])
        }
        False -> {
          io.println_error("Invalid arg: '" <> arg <> "'")
          shellout.exit(1)
          Error(Nil)
        }
      }
    }
  }

  case res {
    Ok(_) -> Nil
    Error(_) -> {
      io.println_error(cmd <> " failed")
      shellout.exit(1)
    }
  }
}
