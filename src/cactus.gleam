import cactus/run
import cactus/util.{type CactusErr, CLIErr}
import cactus/write
import filepath
import gleam/io
import gleam/list
import gleam/result
import gxyz/cli
import platform
import shellout
import simplifile

fn get_cmd() -> String {
  shellout.arguments()
  |> cli.strip_js_from_argv()
  |> list.last()
  |> result.unwrap("")
}

const help_header = "    _
   | |  _
 _ | | | |
| || |_| |                 _
| || |_,_|   ___ __ _  ___| |_ _   _ ___
 \\_| |      / __/ _` |/ __| __| | | / __|
   | |     | (_| (_| | (__| |_| |_| \\__ \\
   |_|      \\___\\__,_|\\___|\\__|\\__,_|___/
"

const help_body = "
version: 1.3.4
--------------------------------------------
A tool for managing git lifecycle hooks with
✨ gleam! Pre commit, Pre push
and more!

Usage:
1. Configure your desired hooks in your project's `gleam.toml`
  - More info: https://github.com/bwireman/cactus?tab=readme-ov-file#config
2. Run `gleam run --target <erlang|javascript> -m cactus`
3. Celebrate! 🎉
"

pub fn main() -> Result(Nil, CactusErr) {
  use pwd <- result.map(util.as_fs_err(simplifile.current_directory(), "."))
  let gleam_toml = filepath.join(pwd, "gleam.toml")
  let hooks_dir =
    pwd
    |> filepath.join(".git")
    |> filepath.join("hooks")

  let cmd = get_cmd()
  let res = case cmd {
    "help" | "--help" | "-h" | "-help" -> {
      util.format_success(help_header)
      |> io.print()

      util.format_info(help_body)
      |> io.print()

      Ok(Nil)
    }

    "windows-init" ->
      write.init(hooks_dir, gleam_toml, True)
      |> result.replace(Nil)

    "unix-init" ->
      write.init(hooks_dir, gleam_toml, False)
      |> result.replace(Nil)

    "" | "init" ->
      write.init(hooks_dir, gleam_toml, platform.os() == platform.Win32)
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
      util.print_warning(util.err_as_str(CLIErr(err)))
      shellout.exit(1)
    }

    Error(reason) -> {
      [util.quote(cmd), "hook failed. Reason:", util.err_as_str(reason)]
      |> util.join_text()
      |> util.print_warning()
      shellout.exit(1)
    }
  }
}
