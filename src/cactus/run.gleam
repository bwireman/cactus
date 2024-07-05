import cactus/errors.{ActionFailed, InvalidToml, MissingField, as_err}
import cactus/util
import gleam/io
import gleam/list
import gleam/result.{try}
import gleam/string
import shellout
import tom.{type Toml}

pub type ActionKind {
  Module
  SubCommand
  Binary
}

pub type Action {
  Action(command: String, kind: ActionKind, args: List(String))
}

pub fn parse_action(raw: Toml) {
  case raw {
    tom.InlineTable(t) -> {
      use command <- try(as_err(
        tom.get_string(t, ["command"]),
        MissingField("command"),
      ))
      let kind =
        tom.get_string(t, ["kind"])
        |> result.map(string.lowercase)
        |> result.unwrap("module")

      let args =
        tom.get_array(t, ["args"])
        |> result.unwrap([])
        |> list.map(as_string)

      let action_kind = case kind {
        "module" -> Module
        "sub_command" -> SubCommand
        "binary" -> Binary
        _ -> Module
      }

      Ok(Action(command: command, kind: action_kind, args: args))
    }
    _ -> Error(InvalidToml)
  }
}

pub fn get_actions(path: String, action: String) {
  use manifest <- try(util.parse_gleam_toml(path))
  use action_body <- try(as_err(
    tom.get_table(manifest, ["cactus", action]),
    MissingField("cactus." <> action),
  ))
  as_err(
    tom.get_array(action_body, ["actions"]),
    MissingField("cactus." <> action <> ".actions"),
  )
}

pub fn run(path: String, action: String) {
  use actions <- try(get_actions(path, action))
  actions
  |> list.map(parse_action)
  |> list.map(fn(parse_result) {
    result.try(parse_result, fn(action) {
      let #(bin, args) = case action.kind {
        Module -> #(
          "gleam",
          list.append(["run", "-m", action.command, "--"], action.args),
        )
        SubCommand -> #("gleam", list.append([action.command], action.args))
        Binary -> #(action.command, action.args)
      }

      io.println("Running: " <> bin <> " " <> string.join(args, " "))
      case shellout.command(run: bin, with: args, in: ".", opt: []) {
        Ok(res) -> {
          io.print(res)
          Ok(res)
        }
        Error(#(_, err)) -> {
          io.print_error(err)
          Error(ActionFailed)
        }
      }
    })
  })
  |> result.all
}

pub fn as_string(t: Toml) {
  case t {
    tom.String(x) -> x
    _ -> {
      io.println_error("Invalid toml field")
      shellout.exit(1)
      panic as "unreachable"
    }
  }
}
