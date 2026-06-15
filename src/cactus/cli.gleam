import cactus/run
import filepath
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gxyz/cli

pub type CliOptions {
  CliOptions(
    verbose: Bool,
    dry_run: Bool,
    config_path: Option(String),
    command: String,
  )
}

pub fn default_options() -> CliOptions {
  CliOptions(verbose: False, dry_run: False, config_path: None, command: "")
}

pub fn parse_args(raw: List(String)) -> CliOptions {
  let stripped = cli.strip_js_from_argv(raw)
  parse_args_loop(stripped, default_options(), [])
}

pub fn to_run_options(opts: CliOptions) -> run.RunOptions {
  run.RunOptions(verbose: opts.verbose, dry_run: opts.dry_run)
}

fn parse_args_loop(
  args: List(String),
  opts: CliOptions,
  commands: List(String),
) -> CliOptions {
  case args {
    [] -> CliOptions(..opts, command: list.last(commands) |> result.unwrap(""))
    ["--verbose", ..rest] ->
      parse_args_loop(rest, CliOptions(..opts, verbose: True), commands)
    ["--dry-run", ..rest] ->
      parse_args_loop(rest, CliOptions(..opts, dry_run: True), commands)
    ["--config", path, ..rest] ->
      parse_args_loop(
        rest,
        CliOptions(..opts, config_path: Some(path)),
        commands,
      )
    [arg, ..]
      if arg == "--help" || arg == "-h" || arg == "-help" || arg == "help"
    -> CliOptions(..opts, command: "help")
    [arg, ..rest] -> parse_args_loop(rest, opts, list.append(commands, [arg]))
  }
}

pub fn resolve_config_path(opts: CliOptions, pwd: String) -> String {
  case opts.config_path {
    Some(path) ->
      case filepath.is_absolute(path) {
        True -> path
        False -> filepath.join(pwd, path)
      }
    None -> filepath.join(pwd, "gleam.toml")
  }
}
