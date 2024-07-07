import cactus/util.{type CactusErr, as_fs_err, as_invalid_field_err, cactus}
import filepath
import gleam/dict
import gleam/io
import gleam/list
import gleam/result.{try}
import gleam/set
import simplifile
import tom

pub const tmpl = "gleam run -m cactus -- "

const valid_hooks = [
  "applypatch-msg", "commit-msg", "fsmonitor-watchman", "post-update",
  "pre-applypatch", "pre-commit", "pre-merge-commit", "prepare-commit-msg",
  "pre-push", "pre-rebase", "pre-receive", "push-to-checkout", "update", "test",
]

pub fn is_valid_hook_name(name: String) -> Bool {
  list.contains(valid_hooks, name)
}

pub fn create_script(
  hooks_dir: String,
  command: String,
) -> Result(String, CactusErr) {
  io.println("Initializing hook: " <> util.quote(command))
  let path = filepath.join(hooks_dir, command)
  let all =
    set.from_list([simplifile.Read, simplifile.Write, simplifile.Execute])

  let _ = simplifile.create_directory(hooks_dir)
  let _ = simplifile.create_file(path)
  use _ <- try(as_fs_err(simplifile.write(path, tmpl <> command), path))

  simplifile.set_permissions(
    path,
    simplifile.FilePermissions(user: all, group: all, other: all),
  )
  |> result.replace(command)
  |> as_fs_err(path)
}

pub fn init(hooks_dir: String, path: String) -> Result(List(String), CactusErr) {
  {
    use manifest <- try(util.parse_gleam_toml(path))
    use action_body <- result.map(
      as_invalid_field_err(tom.get_table(manifest, [cactus])),
    )

    action_body
    |> dict.keys()
    |> list.filter(is_valid_hook_name)
    |> list.map(create_script(hooks_dir, _))
    |> result.all
  }
  |> result.flatten
}
