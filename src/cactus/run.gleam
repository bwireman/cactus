import cactus/util
import gleam/io
import gleam/list
import gleam/result.{try}
import gleam/string
import shellout
import tom.{type Toml}

type ActionKind {
  Module
  SubCommand
  Binary
}

type Action {
  Action(command: String, kind: ActionKind, args: List(String))
}

fn parse(raw: Toml) {
  case raw {
    tom.InlineTable(t) -> {
      use command <- try(tom.get_string(t, ["command"]))
      use kind <- try(
        tom.get_string(t, ["kind"]) |> result.map(string.lowercase),
      )
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

      Ok(Action(command, action_kind, args))
    }
    _ -> panic as "fuck"
  }
  |> result.nil_error
}

pub fn run(path: String, action: String) {
  use manifest <- try(util.parse_manifest(path))
  use action_body <- try(
    tom.get_table(manifest, ["cactus", action]) |> result.nil_error,
  )
  use actions <- result.try(
    tom.get_array(action_body, ["actions"]) |> result.nil_error,
  )

  actions
  |> list.map(parse)
  |> list.map(fn(parse_result) {
    result.try(parse_result, fn(action) {
      let #(bin, args) = case action.kind {
        Module -> #(
          "gleam",
          list.append(["run", "-m", action.command], action.args),
        )
        SubCommand -> #("gleam", list.append([action.command], action.args))
        Binary -> #(action.command, action.args)
      }

      case shellout.command(run: bin, with: args, in: ".", opt: []) {
        Ok(res) -> {
          io.print(res)
          Ok(Nil)
        }
        Error(#(_, err)) -> {
          io.print_error(err)
          Error(Nil)
        }
      }
    })
  })
  |> result.all
  |> result.nil_error
}

pub fn as_string(t: Toml) {
  case t {
    tom.String(x) -> x
    _ -> panic as "invalid toml"
  }
}
