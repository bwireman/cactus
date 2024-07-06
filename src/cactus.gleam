import cactus/run
import cactus/util.{type CactusErr, CLIErr, as_fs_err, str}
import cactus/write
import filepath
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import shellout
import simplifile

fn not_ends_with(v: String, suffix: String) -> Bool {
  !string.ends_with(v, suffix)
}

fn get_cmd() -> String {
  shellout.arguments()
  |> list.filter(not_ends_with(_, ".js"))
  |> list.filter(not_ends_with(_, ".mjs"))
  |> list.filter(not_ends_with(_, ".cjs"))
  |> list.last()
  |> result.unwrap("")
}

pub fn main() -> Result(Nil, CactusErr) {
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
      case write.is_valid_hook_name(arg) {
        True -> run.run(gleam_toml, arg)
        False -> Error(CLIErr(arg))
      }
    }
  }

  case res {
    Ok(_) -> Nil
    Error(reason) -> {
      io.println_error(
        util.quote(cmd) <> " hook failed. Reason: " <> str(reason),
      )
      shellout.exit(1)
    }
  }
}
