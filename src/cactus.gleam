import cactus/errors.{CLIErr, as_fs_err, str}
import cactus/run
import cactus/write.{valid_hooks}
import filepath
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import shellout
import simplifile

fn get_cmd() {
  shellout.arguments()
  |> list.filter(fn(a) { !string.ends_with(a, ".js") })
  |> list.filter(fn(a) { !string.ends_with(a, ".mjs") })
  |> list.filter(fn(a) { !string.ends_with(a, ".cjs") })
  |> list.last()
  |> result.unwrap("")
}

pub fn main() {
  use pwd <- result.map(as_fs_err(simplifile.current_directory(), "."))
  let gleam_toml = filepath.join(pwd, "gleam.toml")
  let hooks_dir =
    pwd
    |> filepath.join(".git")
    |> filepath.join("hooks")

  let cmd = get_cmd()
  let res = case cmd {
    "" | "init" -> {
      write.init(hooks_dir, gleam_toml)
    }

    arg -> {
      case list.contains(valid_hooks, arg) {
        True -> run.run(gleam_toml, arg)
        False -> Error(CLIErr(arg))
      }
    }
  }

  case res {
    Ok(_) -> Nil
    Error(reason) -> {
      io.println_error("'" <> cmd <> "' hook failed. Reason: " <> str(reason))
      shellout.exit(1)
    }
  }
}
