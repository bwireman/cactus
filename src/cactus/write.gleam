import cactus/util.{
  type CactusErr, as_fs_err, as_invalid_field_err, cactus, parse_gleam_toml,
  print_progress, quote,
}
import filepath
import gleam/dict
import gleam/list
import gleam/result.{try}
import gleam/set
import simplifile
import tom

const valid_hooks = [
  "applypatch-msg", "commit-msg", "fsmonitor-watchman", "post-update",
  "pre-applypatch", "pre-commit", "pre-merge-commit", "prepare-commit-msg",
  "pre-push", "pre-rebase", "pre-receive", "push-to-checkout", "update", "test",
]

@target(javascript)
pub fn tmpl(path: String) -> String {
  let runtime =
    path
    |> parse_gleam_toml()
    |> try(fn(gleam_toml) {
      as_invalid_field_err(tom.get_table(gleam_toml, ["javascript"]))
    })
    |> try(fn(gleam_toml) {
      as_invalid_field_err(tom.get_string(gleam_toml, ["runtime"]))
    })
    |> result.unwrap("nodejs")

  "gleam run --target javascript --runtime " <> runtime <> " -m cactus -- "
}

@target(erlang)
pub fn tmpl(_: String) -> String {
  "gleam run --target erlang -m cactus -- "
}

pub fn is_valid_hook_name(name: String) -> Bool {
  list.contains(valid_hooks, name)
}

pub fn create_script(
  hooks_dir: String,
  gleam_path: String,
  command: String,
) -> Result(String, CactusErr) {
  print_progress("Initializing hook: " <> quote(command))
  let path = filepath.join(hooks_dir, command)
  let all =
    set.from_list([simplifile.Read, simplifile.Write, simplifile.Execute])

  let _ = simplifile.create_directory(hooks_dir)
  let _ = simplifile.create_file(path)
  use _ <- try(as_fs_err(
    simplifile.write(path, tmpl(gleam_path) <> command),
    path,
  ))

  simplifile.set_permissions(
    path,
    simplifile.FilePermissions(user: all, group: all, other: all),
  )
  |> result.replace(command)
  |> as_fs_err(path)
}

pub fn init(hooks_dir: String, path: String) -> Result(List(String), CactusErr) {
  {
    use manifest <- try(parse_gleam_toml(path))
    use action_body <- result.map(
      as_invalid_field_err(tom.get_table(manifest, [cactus])),
    )

    action_body
    |> dict.keys()
    |> list.filter(is_valid_hook_name)
    |> list.map(create_script(hooks_dir, path, _))
    |> result.all
  }
  |> result.flatten
}
