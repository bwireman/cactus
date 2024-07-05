import git_gleam_hooks/run
import git_gleam_hooks/util
import git_gleam_hooks/write.{valid_hooks}
import gleam/io
import gleam/list
import gleam/result.{replace}
import shellout

pub fn main() {
  let gleam_toml = util.toml_path()

  let cmd =
    shellout.arguments()
    |> list.last()
    |> result.unwrap("")

  let res = case cmd {
    "" | "init" -> {
      write.init(gleam_toml)
    }

    arg -> {
      case list.contains(valid_hooks, arg) {
        True -> {
          run.run(gleam_toml, arg)
          |> replace(Nil)
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
