import cactus/errors.{MissingFieldErr, as_err, as_fs_err}
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
pub const tmpl = "gleam run -m cactus --target erlang -- "

@target(javascript)
pub const tmpl = "gleam run -m cactus --target javascript -- "

pub const valid_hooks = [
  "applypatch-msg", "commit-msg", "fsmonitor-watchman", "post-update",
  "pre-applypatch", "pre-commit", "pre-merge-commit", "prepare-commit-msg",
  "pre-push", "pre-rebase", "pre-receive", "push-to-checkout", "update",
]

pub fn create_script(hooks_dir: String, command: String) {
  io.println("Initializing hook: '" <> command <> "'")
  let path = filepath.join(hooks_dir, command)

  let _ = simplifile.create_directory(hooks_dir)
  let _ = simplifile.create_file(path)
  use _ <- try(as_fs_err(simplifile.write(path, tmpl <> command), path))

  let all =
    set.from_list([simplifile.Read, simplifile.Write, simplifile.Execute])

  simplifile.set_permissions(
    path,
    simplifile.FilePermissions(user: all, group: all, other: all),
  )
  |> result.replace(command)
  |> as_fs_err(path)
}

pub fn init(hooks_dir: String, path: String) {
  {
    use manifest <- try(util.parse_gleam_toml(path))
    use action_body <- result.map(as_err(
      tom.get_table(manifest, ["cactus"]),
      MissingFieldErr("cactus"),
    ))

    action_body
    |> dict.keys()
    |> list.filter(list.contains(valid_hooks, _))
    |> list.map(create_script(hooks_dir, _))
    |> result.all
  }
  |> result.flatten
}
