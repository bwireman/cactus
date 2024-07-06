import cactus/util.{
  type CactusErr, ActionFailedErr, InvalidFieldCustomErr, as_invalid_field_err,
  cactus,
}
import gleam/io
import gleam/list
import gleam/result.{try}
import gleam/string
import shellout
import tom.{type Toml}

const actions = "actions"

const gleam = "gleam"

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
    tom.InlineTable(t) -> {
      use command <- try(as_invalid_field_err(tom.get_string(t, ["command"])))
      let kind =
        tom.get_string(t, ["kind"])
        |> result.map(string.lowercase)
        |> result.unwrap("module")

      use args <- try(
        tom.get_array(t, ["args"])
        |> result.unwrap([])
        |> list.map(as_string)
        |> result.all(),
      )

      use action_kind <- try(case kind {
        "module" -> Ok(Module)
        "sub_command" -> Ok(SubCommand)
        "binary" -> Ok(Binary)
        _ ->
          Error(InvalidFieldCustomErr(
            "kind",
            "got: "
              <> util.quote(kind)
              <> " expected: one of ['sub_command', 'binary', or 'module']",
          ))
      })

      Ok(Action(command: command, kind: action_kind, args: args))
    }
    _ ->
      Error(InvalidFieldCustomErr(
        actions,
        "'actions' element was not an InlineTable",
      ))
  }
}

pub fn get_actions(
  path: String,
  action: String,
) -> Result(List(Toml), CactusErr) {
  use manifest <- try(util.parse_gleam_toml(path))
  use action_body <- try(
    as_invalid_field_err(tom.get_table(manifest, [cactus, action])),
  )
  as_invalid_field_err(tom.get_array(action_body, [actions]))
}

pub fn run(path: String, action: String) -> Result(List(String), CactusErr) {
  use actions <- try(get_actions(path, action))
  actions
  |> list.map(parse_action)
  |> list.map(fn(parse_result) {
    result.try(parse_result, fn(action) {
      let #(bin, args) = case action.kind {
        Module -> #(gleam, ["run", "-m", action.command, "--", ..action.args])
        SubCommand -> #(gleam, [action.command, ..action.args])
        Binary -> #(action.command, action.args)
      }

      io.println(string.join(["Running", bin, ..args], " "))
      case shellout.command(run: bin, with: args, in: ".", opt: []) {
        Ok(res) -> {
          io.print(res)
          Ok(res)
        }
        Error(#(_, err)) -> Error(ActionFailedErr(err))
      }
    })
  })
  |> result.all
}

pub fn as_string(t: Toml) -> Result(String, CactusErr) {
  case t {
    tom.String(v) -> Ok(v)
    _ ->
      Error(InvalidFieldCustomErr("args", "'args' was not a list of strings"))
  }
}
