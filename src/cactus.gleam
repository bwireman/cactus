import cactus/run
import cactus/util.{
  type CactusErr, CLIErr, as_fs_err, err_as_str, join_text, print_info,
  print_warning, quote,
}
import cactus/write
import filepath
import gleam/list
import gleam/result
import gleam/string
import gxyz/gxyz_list.{reject}
import shellout
import simplifile

fn get_cmd() -> String {
  shellout.arguments()
  |> reject(string.ends_with(_, ".js"))
  |> reject(string.ends_with(_, ".mjs"))
  |> reject(string.ends_with(_, ".cjs"))
  |> list.last()
  |> result.unwrap("")
}

const help = "
🌵 Cactus (version: 1.3.0)
---------------------------------------
A tool for managing git lifecycle hooks
with ✨ gleam! Pre commit, Pre push
and more!

Usage:
1. Configure your desired hooks in your project's `gleam.toml`
  - More info: https://github.com/bwireman/cactus?tab=readme-ov-file#%EF%B8%8F-config
2. Run `gleam run --target <erlang|javascript> -m cactus`
3. Celebrate! 🎉
"

pub fn main() -> Result(Nil, CactusErr) {
  use pwd <- result.map(as_fs_err(simplifile.current_directory(), "."))
  let gleam_toml = filepath.join(pwd, "gleam.toml")
  let hooks_dir =
    pwd
    |> filepath.join(".git")
    |> filepath.join("hooks")

  let cmd = get_cmd()
  let res = case cmd {
    "help" | "--help" | "-h" -> Ok(print_info(help))

    "windows-init" ->
      write.init(hooks_dir, gleam_toml, True)
      |> result.replace(Nil)

    "" | "init" ->
      write.init(hooks_dir, gleam_toml, False)
      |> result.replace(Nil)

    arg -> {
      let _ = case util.parse_always_init(gleam_toml) {
        True -> write.init(hooks_dir, gleam_toml, False)
        _ -> Ok([])
      }

      case write.is_valid_hook_name(arg) {
        True -> run.run(gleam_toml, arg)
        False -> Error(CLIErr(arg))
      }
      |> result.replace(Nil)
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
