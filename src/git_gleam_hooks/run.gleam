import gleam/io
import gleam/list
import gleam/result
import gleam/string
import shellout
import simplifile
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
      let assert Ok(command) = tom.get_string(t, ["command"])
      let assert Ok(kind) =
        tom.get_string(t, ["kind"]) |> result.map(string.lowercase)

      let action_kind = case kind {
        "module" -> Module
        "sub_command" -> SubCommand
        "binary" -> Binary
        _ -> Module
      }

      Action(command, action_kind)
    }
    _ -> panic as "fuck"
  }
}

pub fn run(path: String, action: String) {
  let assert Ok(body) = simplifile.read(path)
  let assert Ok(manifest) = tom.parse(body)
  let assert Ok(action_body) = tom.get_table(manifest, ["hooks", action])
  let assert Ok(actions) = tom.get_array(action_body, ["actions"])

  actions
  |> list.map(parse)
  |> list.map(fn(action) {
    let #(bin, args) = case action.kind {
      Module -> #("gleam", ["run", "-m", action.command])
      SubCommand -> #("gleam", [action.command])
      Binary -> #(action.command, [])
    }
    let assert Ok(res) =
      shellout.command(run: bin, with: args, in: ".", opt: [])

    io.print(res)
  })
}
