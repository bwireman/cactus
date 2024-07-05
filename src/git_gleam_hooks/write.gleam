import filepath
import gleam/dict
import gleam/list
import gleam/result
import gleam/set
import simplifile
import tom

@target(erlang)
const tmpl = "gleam run -m git_gleam_hooks --target erlang -- "

@target(javascript)
const tmpl = "gleam run -m git_gleam_hooks --target javascript -- "

pub const valid_hooks = [
  "applypatch-msg", "commit-msg", "fsmonitor-watchman", "post-update",
  "pre-applypatch", "pre-commit", "pre-merge-commit", "prepare-commit-msg",
  "pre-push", "pre-rebase", "pre-receive", "push-to-checkout", "update",
]

fn write(command: String) {
  use pwd <- result.try(simplifile.current_directory())
  let path =
    pwd
    |> filepath.join(".git")
    |> filepath.join("hooks")
    |> filepath.join(command)

  let _ = simplifile.create_file(path)
  use _ <- result.try(simplifile.write(path, tmpl <> command))

  let all =
    set.from_list([simplifile.Read, simplifile.Write, simplifile.Execute])

  let _ =
    simplifile.set_permissions(
      path,
      simplifile.FilePermissions(user: all, group: all, other: all),
    )
}

pub fn init(path: String) {
  use body <- result.try(simplifile.read(path) |> result.nil_error)
  use manifest <- result.try(tom.parse(body) |> result.nil_error)
  use action_body <- result.map(
    tom.get_table(manifest, ["hooks"]) |> result.nil_error,
  )

  action_body
  |> dict.keys()
  |> list.filter(list.contains(valid_hooks, _))
  |> list.map(write)
  Nil
}
