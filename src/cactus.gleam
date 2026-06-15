import cactus/cli
import cactus/run
import cactus/util.{
  type CactusErr, ActionFailedErr, CLIErr, as_fs_err, err_as_str, format_info,
  format_success, get_package_version, join_text, parse_always_init,
  print_warning, quote,
}
import cactus/write
import filepath
import gleam/io
import gleam/result
import platform
import shellout
import simplifile

const help_header = "    _
   | |  _
 _ | | | |
| || |_| |                 _
| || |_,_|   ___ __ _  ___| |_ _   _ ___
 \\_| |      / __/ _` |/ __| __| | | / __|
   | |     | (_| (_| | (__| |_| |_| \\__ \\
   |_|      \\___\\__,_|\\___|\\__|\\__,_|___/
"

fn help_body(version: String) -> String {
  "
version: " <> version <> "
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
}

fn windows_hooks() -> Bool {
  platform.os() == platform.Win32
}

pub fn main() -> Result(Nil, CactusErr) {
  use pwd <- result.map(as_fs_err(simplifile.current_directory(), "."))
  let cli_opts = cli.parse_args(shellout.arguments())
  let gleam_toml = cli.resolve_config_path(cli_opts, pwd)
  let hooks_dir =
    pwd
    |> filepath.join(".git")
    |> filepath.join("hooks")
  let run_opts = cli.to_run_options(cli_opts)

  let cmd = cli_opts.command
  let res = case cmd {
    "help" -> {
      format_success(help_header)
      |> io.print()

      let version =
        get_package_version(gleam_toml)
        |> result.unwrap("unknown")

      format_info(help_body(version))
      |> io.print()

      Ok(Nil)
    }

    "clean" ->
      write.clean(hooks_dir)
      |> result.replace(Nil)

    "windows-init" ->
      write.init(hooks_dir, gleam_toml, True)
      |> result.replace(Nil)

    "unix-init" ->
      write.init(hooks_dir, gleam_toml, False)
      |> result.replace(Nil)

    "" | "init" ->
      write.init(hooks_dir, gleam_toml, windows_hooks())
      |> result.replace(Nil)

    arg -> {
      let _ = case parse_always_init(gleam_toml) {
        True -> write.init(hooks_dir, gleam_toml, windows_hooks())
        _ -> Ok([])
      }

      case write.is_valid_hook_name(arg) {
        True -> run.run(gleam_toml, arg, run_opts)
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
      let message = case reason {
        ActionFailedErr(_, _, _, _) -> err_as_str(reason)
        _ ->
          [quote(cmd), "hook failed. Reason:", err_as_str(reason)]
          |> join_text()
      }
      print_warning(message)
      shellout.exit(1)
    }
  }
}
