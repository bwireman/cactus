import cactus/git
import cactus/modified.{
  type FilesScope, default_files_scope, files_scope_label,
  filter_files_under_cwd, get_files_for_scope_in, modified_files_match,
  parse_files_scope,
}
import cactus/util.{
  type CactusErr, ActionFailedErr, InvalidFieldErr, as_invalid_field_err, cactus,
  drop_empty, join_text, parse_gleam_toml, print_info, print_progress,
  print_verbose, print_warning, quote,
}
import envoy
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result.{all, map, try, unwrap}
import gleam/string
import gleither.{Left, Right}
import shellout.{SetEnvironment, command}
import tom.{type Toml, NotFound}

const actions = "actions"

const gleam = "gleam"

const stash_hooks = ["pre-commit", "pre-merge-commit"]

pub type RunOptions {
  RunOptions(verbose: Bool, dry_run: Bool)
}

pub type FailMode {
  Stop
  Continue
}

pub type ActionKind {
  Module
  SubCommand
  Binary
}

pub type Action {
  Action(
    command: String,
    kind: ActionKind,
    args: List(String),
    files: List(String),
    files_scope: FilesScope,
    cwd: String,
    env: List(#(String, String)),
    skip_env: Option(String),
  )
}

pub type HookConfig {
  HookConfig(
    files_scope: FilesScope,
    on_failure: FailMode,
    skip_env: Option(String),
    actions: List(Action),
  )
}

fn do_parse_kind(kind: String) -> Result(ActionKind, CactusErr) {
  case kind {
    "module" -> Ok(Module)
    "sub_command" -> Ok(SubCommand)
    "binary" -> Ok(Binary)
    _ ->
      Error(InvalidFieldErr(
        "kind",
        Right(
          join_text([
            "got:",
            quote(kind),
            "expected: one of ['sub_command', 'binary', or 'module']",
          ]),
        ),
      ))
  }
}

fn parse_skip_env(raw: String) -> Result(Option(String), CactusErr) {
  case string.split_once(string.trim(raw), on: "=") {
    Ok(#(name, value)) ->
      case name, value {
        "", _ ->
          Error(InvalidFieldErr(
            "skip_env",
            Right("expected NAME=value, got: " <> quote(raw)),
          ))
        _, "" ->
          Error(InvalidFieldErr(
            "skip_env",
            Right("expected NAME=value, got: " <> quote(raw)),
          ))
        _, _ -> Ok(Some(name <> "=" <> value))
      }
    Error(_) ->
      Error(InvalidFieldErr(
        "skip_env",
        Right("expected NAME=value, got: " <> quote(raw)),
      ))
  }
}

fn parse_skip_env_field(
  t: Dict(String, Toml),
  key: String,
) -> Result(Option(String), CactusErr) {
  case tom.get_string(t, [key]) {
    Ok(raw) -> parse_skip_env(raw)
    Error(NotFound(_)) -> Ok(None)
    Error(err) -> Error(InvalidFieldErr(key, Left(err)))
  }
}

fn parse_files_scope_field(
  t: Dict(String, Toml),
  default: FilesScope,
) -> Result(FilesScope, CactusErr) {
  case tom.get_string(t, ["files_scope"]) {
    Ok(raw) -> parse_files_scope(raw)
    Error(_) -> Ok(default)
  }
}

fn parse_env_table(
  t: Dict(String, Toml),
) -> Result(List(#(String, String)), CactusErr) {
  case dict.get(t, "env") {
    Ok(tom.InlineTable(env)) ->
      env
      |> dict.to_list()
      |> list.map(fn(pair) {
        case pair {
          #(key, tom.String(value)) -> Ok(#(key, value))
          _ ->
            Error(InvalidFieldErr("env", Right("'env' values must be strings")))
        }
      })
      |> all()
    Ok(_) ->
      Error(InvalidFieldErr("env", Right("'env' must be an inline table")))
    Error(_) -> Ok([])
  }
}

fn do_parse_action(
  t: Dict(String, Toml),
  hook_default: FilesScope,
) -> Result(Action, CactusErr) {
  let kind =
    tom.get_string(t, ["kind"])
    |> map(string.lowercase)
    |> unwrap("module")

  use command <- try(as_invalid_field_err(tom.get_string(t, ["command"])))
  use args <- try(
    tom.get_array(t, ["args"])
    |> unwrap([])
    |> list.map(as_string)
    |> all(),
  )
  use files <- try(
    tom.get_array(t, ["files"])
    |> unwrap([])
    |> list.map(as_string)
    |> all(),
  )
  use files_scope <- try(parse_files_scope_field(t, hook_default))
  use action_kind <- try(do_parse_kind(kind))
  use env <- try(parse_env_table(t))
  use skip_env <- try(parse_skip_env_field(t, "skip_env"))

  Ok(Action(
    command: command,
    kind: action_kind,
    args: args,
    files: files,
    files_scope: files_scope,
    cwd: tom.get_string(t, ["cwd"]) |> unwrap("."),
    env: env,
    skip_env: skip_env,
  ))
}

fn as_string(t: Toml) -> Result(String, CactusErr) {
  case t {
    tom.String(v) -> Ok(v)
    _ ->
      Error(InvalidFieldErr("args", Right("'args' was not a list of strings")))
  }
}

fn parse_fail_mode(raw: String) -> Result(FailMode, CactusErr) {
  case string.lowercase(string.trim(raw)) {
    "stop" -> Ok(Stop)
    "continue" -> Ok(Continue)
    _ ->
      Error(InvalidFieldErr(
        "on_failure",
        Right("expected 'stop' or 'continue', got: " <> quote(raw)),
      ))
  }
}

fn parse_hook_table(
  action_body: Dict(String, Toml),
) -> Result(HookConfig, CactusErr) {
  use hook_files_scope <- try(parse_files_scope_field(
    action_body,
    default_files_scope(),
  ))
  use on_failure <- try(case tom.get_string(action_body, ["on_failure"]) {
    Ok(raw) -> parse_fail_mode(raw)
    Error(_) -> Ok(Stop)
  })
  use skip_env <- try(parse_skip_env_field(action_body, "skip_env"))

  use raw_actions <- try(
    as_invalid_field_err(tom.get_array(action_body, [actions])),
  )

  use parsed_actions <- try(
    raw_actions
    |> list.map(fn(raw) {
      case raw {
        tom.InlineTable(t) -> do_parse_action(t, hook_files_scope)
        _ ->
          Error(InvalidFieldErr(
            actions,
            Right("'actions' element was not an InlineTable"),
          ))
      }
    })
    |> all(),
  )

  Ok(HookConfig(
    files_scope: hook_files_scope,
    on_failure: on_failure,
    skip_env: skip_env,
    actions: parsed_actions,
  ))
}

pub fn parse_action(raw: Toml) -> Result(Action, CactusErr) {
  case raw {
    tom.InlineTable(t) -> do_parse_action(t, default_files_scope())
    _ ->
      Error(InvalidFieldErr(
        actions,
        Right("'actions' element was not an InlineTable"),
      ))
  }
}

pub fn get_hook_config(
  path: String,
  hook: String,
) -> Result(HookConfig, CactusErr) {
  use manifest <- try(parse_gleam_toml(path))
  use action_body <- try(
    as_invalid_field_err(tom.get_table(manifest, [cactus, hook])),
  )
  parse_hook_table(action_body)
}

pub fn get_actions(
  path: String,
  action: String,
) -> Result(List(Toml), CactusErr) {
  use manifest <- try(parse_gleam_toml(path))
  use action_body <- try(
    as_invalid_field_err(tom.get_table(manifest, [cactus, action])),
  )
  as_invalid_field_err(tom.get_array(action_body, [actions]))
}

fn should_skip(skip_env: Option(String)) -> Bool {
  case skip_env {
    Some(raw) ->
      case string.split_once(raw, on: "=") {
        Ok(#(name, value)) ->
          case envoy.get(name) {
            Ok(found) -> found == value
            Error(_) -> False
          }
        Error(_) -> False
      }
    None -> False
  }
}

fn action_invocation(action: Action) -> #(String, List(String)) {
  case action.kind {
    Module -> #(gleam, ["run", "-m", action.command, "--", ..action.args])
    SubCommand -> #(gleam, [action.command, ..action.args])
    Binary -> #(action.command, action.args)
  }
}

fn action_label(action: Action) -> String {
  let #(bin, args) = action_invocation(action)
  join_text([bin, ..args])
}

fn do_run(
  action: Action,
  index: Int,
  total: Int,
  hook_skip_env: Option(String),
  opts: RunOptions,
) -> Result(String, CactusErr) {
  let skip_env = option.or(action.skip_env, hook_skip_env)
  let label = action_label(action)

  case should_skip(skip_env) {
    True -> {
      print_verbose(
        opts.verbose,
        "Skipping " <> quote(label) <> " (skip_env matched)",
      )
      Ok("")
    }
    False -> {
      use run_action <- try(case list.is_empty(drop_empty(action.files)) {
        True -> Ok(True)
        False -> {
          use modified_files <- try(get_files_for_scope_in(
            ".",
            action.files_scope,
          ))
          let modified_files =
            filter_files_under_cwd(modified_files, action.cwd)
          print_verbose(
            opts.verbose,
            "Checking files ("
              <> files_scope_label(action.files_scope)
              <> "): "
              <> quote(label),
          )
          Ok(modified_files_match(modified_files, action.files))
        }
      })

      case run_action {
        True -> {
          case opts.dry_run {
            True -> {
              print_info(
                "[dry-run] Would run "
                <> quote(label)
                <> " in "
                <> quote(action.cwd),
              )
              Ok("")
            }
            False -> {
              let #(bin, args) = action_invocation(action)
              print_progress("Running " <> quote(label))
              case
                command(run: bin, with: args, in: action.cwd, opt: [
                  SetEnvironment(action.env),
                ])
              {
                Ok(res) -> {
                  io.print(res)
                  Ok(res)
                }
                Error(#(_, err)) ->
                  Error(ActionFailedErr(
                    index: index,
                    total: total,
                    command: label,
                    output: err,
                  ))
              }
            }
          }
        }
        False -> {
          print_verbose(
            opts.verbose,
            "Skipping " <> quote(label) <> " (no matching files)",
          )
          Ok("")
        }
      }
    }
  }
}

fn run_hook_actions_with_fail_mode(
  config: HookConfig,
  opts: RunOptions,
) -> Result(List(String), CactusErr) {
  case should_skip(config.skip_env) {
    True -> {
      print_verbose(opts.verbose, "Skipping hook (skip_env matched)")
      Ok([])
    }
    False -> {
      let total = list.length(config.actions)
      run_hook_actions_with_fail_mode_loop(
        config.actions,
        config.skip_env,
        config.on_failure,
        opts,
        total,
        0,
        [],
        None,
      )
    }
  }
}

fn run_hook_actions_with_fail_mode_loop(
  remaining: List(Action),
  hook_skip_env: Option(String),
  on_failure: FailMode,
  opts: RunOptions,
  total: Int,
  index: Int,
  acc: List(String),
  first_err: Option(CactusErr),
) -> Result(List(String), CactusErr) {
  case remaining {
    [] ->
      case first_err {
        Some(err) -> Error(err)
        None -> Ok(list.reverse(acc))
      }
    [action, ..rest] -> {
      let next_index = index + 1
      case do_run(action, next_index, total, hook_skip_env, opts) {
        Ok(output) ->
          run_hook_actions_with_fail_mode_loop(
            rest,
            hook_skip_env,
            on_failure,
            opts,
            total,
            next_index,
            [output, ..acc],
            first_err,
          )
        Error(err) ->
          case on_failure {
            Stop -> Error(err)
            Continue ->
              run_hook_actions_with_fail_mode_loop(
                rest,
                hook_skip_env,
                on_failure,
                opts,
                total,
                next_index,
                acc,
                option.or(first_err, Some(err)),
              )
          }
      }
    }
  }
}

fn run_actions(
  path: String,
  hook: String,
  opts: RunOptions,
) -> Result(List(String), CactusErr) {
  use config <- try(get_hook_config(path, hook))
  run_hook_actions_with_fail_mode(config, opts)
}

fn run_with_stash(
  path: String,
  hook: String,
  opts: RunOptions,
) -> Result(List(String), CactusErr) {
  print_verbose(opts.verbose, "Stashing unstaged changes for " <> hook)

  use stashed <- try(git.stash_unstaged())
  case stashed {
    False ->
      case git.worktree_has_unstaged_changes() {
        Ok(True) ->
          print_warning(
            "Skipped stashing unstaged changes: an existing git stash was found. "
            <> "Commit or stash manually first so hook actions do not see dirty "
            <> "working-tree state.",
          )
        _ -> Nil
      }
    _ -> Nil
  }
  let action_res = run_actions(path, hook, opts)

  case stashed {
    True -> {
      print_verbose(opts.verbose, "Restoring stashed changes")
      case git.pop_stash_required(), action_res {
        Ok(_), _ -> action_res
        Error(pop_err), _ -> Error(pop_err)
      }
    }
    False -> action_res
  }
}

pub fn run(
  path: String,
  hook: String,
  opts: RunOptions,
) -> Result(List(String), CactusErr) {
  case list.contains(stash_hooks, hook) {
    True -> run_with_stash(path, hook, opts)
    False -> run_actions(path, hook, opts)
  }
}
