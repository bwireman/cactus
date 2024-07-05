import git_gleam_hooks/util
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
  Action(command: String, kind: ActionKind)
}

fn parse(raw: Toml) {
  case raw {
    tom.InlineTable(t) -> {
      use command <- try(tom.get_string(t, ["command"]))
      use kind <- try(
        tom.get_string(t, ["kind"]) |> result.map(string.lowercase),
      )

      let action_kind = case kind {
        "module" -> Module
        "sub_command" -> SubCommand
        "binary" -> Binary
        _ -> Module
      }

      Ok(Action(command, action_kind))
    }
    _ -> panic as "fuck"
  }
}

pub fn run(path: String, action: String) {
  use manifest <- try(util.parse_manifest(path))
  use action_body <- try(
    tom.get_table(manifest, ["hooks", action]) |> result.nil_error,
  )
  use actions <- result.map(
    tom.get_array(action_body, ["actions"]) |> result.nil_error,
  )

  actions
  |> list.map(parse)
  |> list.map(fn(parse_result) {
    result.map(parse_result, fn(action) {
      let #(bin, args) = case action.kind {
        Module -> #("gleam", ["run", "-m", action.command])
        SubCommand -> #("gleam", [action.command])
        Binary -> #(action.command, [])
      }

      case shellout.command(run: bin, with: args, in: ".", opt: []) {
        Ok(res) -> io.print(res)
        Error(#(_, err)) -> io.print_error(err)
      }
    })
  })
}
