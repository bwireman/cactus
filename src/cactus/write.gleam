import cactus/util.{
  type CactusErr, as_fs_err, as_invalid_field_err, cactus, parse_gleam_toml,
  print_progress, quote,
}
import filepath
import gleam/dict
import gleam/list
import gleam/result.{try}
import gleam/set
import gleam/string
@target(javascript)
import platform
import simplifile
import tom

const valid_hooks = [
  "applypatch-msg", "commit-msg", "fsmonitor-watchman", "post-checkout",
  "post-commit", "post-merge", "post-rewrite", "post-update", "pre-applypatch",
  "pre-auto-gc", "pre-commit", "pre-merge-commit", "prepare-commit-msg",
  "pre-push", "pre-rebase", "pre-receive", "push-to-checkout", "update", "test",
]

const cactus_marker = " -m cactus -- "

fn ensure_directory(path: String) -> Result(Nil, CactusErr) {
  case simplifile.create_directory(path) {
    Ok(_) -> Ok(Nil)
    Error(simplifile.Eexist) -> Ok(Nil)
    Error(err) -> as_fs_err(Error(err), path)
  }
}

fn ensure_file(path: String) -> Result(Nil, CactusErr) {
  case simplifile.create_file(path) {
    Ok(_) -> Ok(Nil)
    Error(simplifile.Eexist) -> Ok(Nil)
    Error(err) -> as_fs_err(Error(err), path)
  }
}

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
  <> cactus_marker
}

@target(erlang)
pub fn get_hook_template(windows: Bool) -> String {
  "#!/bin/sh \n\n"
  <> gleam_name(windows)
  <> " run --target erlang"
  <> cactus_marker
}

pub fn is_valid_hook_name(name: String) -> Bool {
  list.contains(valid_hooks, name)
}

pub fn is_cactus_hook(content: String) -> Bool {
  string.contains(content, cactus_marker)
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

  use _ <- try(ensure_directory(hooks_dir))
  use _ <- try(ensure_file(path))
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

pub fn clean(hooks_dir: String) -> Result(List(String), CactusErr) {
  case simplifile.read_directory(hooks_dir) {
    Ok(entries) ->
      entries
      |> list.filter(fn(name) { !list.contains([".", ".."], name) })
      |> list.map(clean_hook(hooks_dir, _))
      |> result.all()
      |> result.map(fn(names) { list.filter(names, fn(name) { name != "" }) })
    Error(_) -> Ok([])
  }
}

fn clean_hook(hooks_dir: String, name: String) -> Result(String, CactusErr) {
  let path = filepath.join(hooks_dir, name)
  use content <- try(as_fs_err(simplifile.read(path), path))
  case is_cactus_hook(content) {
    True -> {
      print_progress("Removing hook: " <> quote(name))
      use _ <- try(as_fs_err(simplifile.delete(path), path))
      Ok(name)
    }
    False -> Ok("")
  }
}
