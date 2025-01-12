import cactus/util.{
  type CactusErr, as_fs_err, as_invalid_field_err, cactus, parse_gleam_toml,
  print_progress, quote,
}
import filepath
import gleam/dict
import gleam/list
import gleam/result.{try}
import gleam/set
@target(javascript)
import platform
import simplifile
import tom

const valid_hooks = [
  "applypatch-msg", "commit-msg", "fsmonitor-watchman", "post-update",
  "pre-applypatch", "pre-commit", "pre-merge-commit", "prepare-commit-msg",
  "pre-push", "pre-rebase", "pre-receive", "push-to-checkout", "update", "test",
]

fn gleam_name(windows: Bool) -> String {
  case windows {
    True -> "gleam.exe"
    False -> "gleam"
  }
}

@target(javascript)
pub fn get_hook_template(windows: Bool) -> String {
  let runtime = case platform.runtime() {
    platform.Node -> "node"
    platform.Bun -> "bun"
    platform.Deno -> "deno"
    _ ->
      panic as "Invalid runtime, please create an issue in https://github.com/bwireman/cactus if you see this"
  }

  "#!/bin/sh \n\n"
  <> gleam_name(windows)
  <> " run --target javascript --runtime "
  <> runtime
  <> " -m cactus -- "
}

@target(erlang)
pub fn get_hook_template(windows: Bool) -> String {
  "#!/bin/sh \n\n"
  <> gleam_name(windows)
  <> " run --target erlang -m cactus -- "
}

pub fn is_valid_hook_name(name: String) -> Bool {
  list.contains(valid_hooks, name)
}

pub fn create_script(
  hooks_dir: String,
  command: String,
  windows: Bool,
) -> Result(String, CactusErr) {
  case command == "test" {
    False -> print_progress("Initializing hook: " <> quote(command))
    _ -> Nil
  }

  let path = filepath.join(hooks_dir, command)
  let all =
    set.from_list([simplifile.Read, simplifile.Write, simplifile.Execute])

  let _ = simplifile.create_directory(hooks_dir)
  let _ = simplifile.create_file(path)
  use _ <- try(as_fs_err(
    simplifile.write(path, get_hook_template(windows) <> command),
    path,
  ))

  simplifile.set_permissions(
    path,
    simplifile.FilePermissions(user: all, group: all, other: all),
  )
  |> result.replace(command)
  |> as_fs_err(path)
}

pub fn init(
  hooks_dir: String,
  path: String,
  windows: Bool,
) -> Result(List(String), CactusErr) {
  {
    use manifest <- try(parse_gleam_toml(path))
    use action_body <- result.map(
      as_invalid_field_err(tom.get_table(manifest, [cactus])),
    )

    action_body
    |> dict.keys()
    |> list.filter(is_valid_hook_name)
    |> list.map(create_script(hooks_dir, _, windows))
    |> result.all()
  }
  |> result.flatten()
}
