import cactus/util
import filepath
import gleam/dict
import gleam/io
import gleam/list
import gleam/result.{try}
import gleam/set
import simplifile
import tom

@target(erlang)
const tmpl = "gleam run -m cactus --target erlang -- "

@target(javascript)
const tmpl = "gleam run -m cactus --target javascript -- "

pub const valid_hooks = [
  "applypatch-msg", "commit-msg", "fsmonitor-watchman", "post-update",
  "pre-applypatch", "pre-commit", "pre-merge-commit", "prepare-commit-msg",
  "pre-push", "pre-rebase", "pre-receive", "push-to-checkout", "update",
]

fn create_script(command: String) {
  io.println("Initializing hook: '" <> command <> "'")
  use pwd <- try(simplifile.current_directory())
  let hooks_path =
    pwd
    |> filepath.join(".git")
    |> filepath.join("hooks")

  let path = filepath.join(hooks_path, command)

  let _ = simplifile.create_directory(hooks_path)
  let _ = simplifile.create_file(path)
  use _ <- try(simplifile.write(path, tmpl <> command))

  let all =
    set.from_list([simplifile.Read, simplifile.Write, simplifile.Execute])

  simplifile.set_permissions(
    path,
    simplifile.FilePermissions(user: all, group: all, other: all),
  )
}

pub fn init(path: String) {
  use manifest <- try(util.parse_manifest(path))
  use action_body <- result.map(
    tom.get_table(manifest, ["cactus"]) |> result.nil_error,
  )

  action_body
  |> dict.keys()
  |> list.filter(list.contains(valid_hooks, _))
  |> list.map(create_script)
  Nil
}
