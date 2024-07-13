import cactus/run
import cactus/util.{
  type CactusErr, CLIErr, as_fs_err, err_as_str, join_text, print_warning, quote,
}
import cactus/write
import filepath
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
    "help" | "--help" | "-h" -> {
      util.print_info(
        "
🌵 Cactus (version: 0.2.1)
---------------------------------------
A tool for managing git lifecycle hooks
with ✨ gleam! Pre commit, Pre push
and more!

Usage:

1. Configure your desired hooks in your project's `gleam.toml`
  - More info: https://github.com/bwireman/cactus?tab=readme-ov-file#%EF%B8%8F-config
2. Run `gleam run -m cactus`
3. Celebrate! 🎉
",
      )
      Ok([])
    }

    "" | "init" -> write.init(hooks_dir, gleam_toml)

    arg ->
      case write.is_valid_hook_name(arg) {
        True -> run.run(gleam_toml, arg)
        False -> Error(CLIErr(arg))
      }
  }

  case res {
    Ok(_) -> Nil
    Error(CLIErr(err)) -> {
      print_warning(err_as_str(CLIErr(err)))
      shellout.exit(1)
    }
    Error(reason) -> {
      [quote(cmd), "hook failed. Reason:", err_as_str(reason)]
      |> join_text()
      |> print_warning()
      shellout.exit(1)
    }
  }
}
