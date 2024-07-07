import cactus/util.{
  type CactusErr, ActionFailedErr, InvalidFieldErr, as_invalid_field_err, cactus,
  join_text, parse_gleam_toml, quote,
}
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/result.{try}
import gleam/string
import gleither.{Right}
import shellout
import tom.{type Toml}

const actions = "actions"

const gleam = "gleam"

fn do_parse_kind(kind: String) -> Result(ActionKind, CactusErr) {
  case kind {
    "module" -> Ok(Module)
    "sub_command" -> Ok(SubCommand)
    "binary" -> Ok(Binary)
    _ ->
      Error(InvalidFieldErr(
        Some("kind"),
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

fn do_parse_action(t: Dict(String, Toml)) -> Result(Action, CactusErr) {
  let kind =
    tom.get_string(t, ["kind"])
    |> result.map(string.lowercase)
    |> result.unwrap("module")

  use command <- try(as_invalid_field_err(tom.get_string(t, ["command"])))
  use args <- try(
    tom.get_array(t, ["args"])
    |> result.unwrap([])
    |> list.map(as_string)
    |> result.all(),
  )
  use action_kind <- result.map(do_parse_kind(kind))

  Action(command: command, kind: action_kind, args: args)
}

fn do_run(action: Action) {
  let #(bin, args) = case action.kind {
    Module -> #(gleam, ["run", "-m", action.command, "--", ..action.args])
    SubCommand -> #(gleam, [action.command, ..action.args])
    Binary -> #(action.command, action.args)
  }

  io.println(join_text(["Running", bin, ..args]))
  case shellout.command(run: bin, with: args, in: ".", opt: []) {
    Ok(res) -> {
      io.print(res)
      Ok(res)
    }
    Error(#(_, err)) -> Error(ActionFailedErr(err))
  }
}

fn as_string(t: Toml) -> Result(String, CactusErr) {
  case t {
    tom.String(v) -> Ok(v)
    _ ->
      Error(InvalidFieldErr(
        Some("args"),
        Right("'args' was not a list of strings"),
      ))
  }
}

pub type ActionKind {
  Module
  SubCommand
  Binary
}

pub type Action {
  Action(command: String, kind: ActionKind, args: List(String))
}

pub fn parse_action(raw: Toml) -> Result(Action, CactusErr) {
  case raw {
    tom.InlineTable(t) -> do_parse_action(t)

    _ ->
      Error(InvalidFieldErr(
        Some(actions),
        Right("'actions' element was not an InlineTable"),
      ))
  }
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

pub fn run(path: String, action: String) -> Result(List(String), CactusErr) {
  use actions <- try(get_actions(path, action))
  actions
  |> list.map(parse_action)
  |> list.map(result.try(_, do_run))
  |> result.all
}
