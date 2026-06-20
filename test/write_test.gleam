import cactus/write
import filepath
import gleam/list
import gleeunit/should
@target(javascript)
import platform
import simplifile

const hook_dir = "test/testdata/scripts"

pub fn init_test() {
  let assert Ok(_) = simplifile.delete_all([hook_dir])

  write.init(hook_dir, "test/testdata/gleam/too_many.toml", False)
  |> should.be_ok()
  |> list.length()
  |> should.equal(13)
}

pub fn create_script_test() {
  let assert Ok(_) =
    simplifile.delete_all([filepath.join(hook_dir, "test"), hook_dir])

  let assert Ok(_) = write.create_script("test/testdata/scripts", "test", False)

  let assert Ok(actual) = simplifile.read("test/testdata/scripts/test")
  assert actual == write.get_hook_template(False) <> "test"
}

pub fn clean_test() {
  let assert Ok(_) = simplifile.delete_all([hook_dir])
  let assert Ok(_) = write.create_script(hook_dir, "test", False)

  write.clean(hook_dir)
  |> should.be_ok()

  case simplifile.read(filepath.join(hook_dir, "test")) {
    Ok(_) -> should.fail()
    Error(_) -> Nil
  }
}

pub fn clean_preserves_user_hooks_test() {
  let user_hook = filepath.join(hook_dir, "user-hook")
  let assert Ok(_) = simplifile.delete_all([hook_dir])
  let assert Ok(_) = simplifile.create_directory(hook_dir)
  let assert Ok(_) =
    simplifile.write(user_hook, "#!/bin/sh\n\necho user hook\n")
  let assert Ok(_) = write.create_script(hook_dir, "test", False)

  write.clean(hook_dir)
  |> should.be_ok()

  simplifile.read(user_hook)
  |> should.be_ok()
  |> should.equal("#!/bin/sh\n\necho user hook\n")

  case simplifile.read(filepath.join(hook_dir, "test")) {
    Ok(_) -> should.fail()
    Error(_) -> Nil
  }
}

@target(javascript)
pub fn get_hook_template_test() {
  let runtime = case platform.runtime() {
    platform.Node -> "node"
    platform.Bun -> "bun"
    platform.Deno -> "deno"
    _ -> panic as "invalid runtime"
  }

  write.get_hook_template(False)
  |> should.equal(
    "#!/bin/sh \n\ngleam run --target javascript --runtime "
    <> runtime
    <> " -m cactus -- ",
  )

  write.get_hook_template(True)
  |> should.equal(
    "#!/bin/sh \n\ngleam.exe run --target javascript --runtime "
    <> runtime
    <> " -m cactus -- ",
  )
}

@target(erlang)
pub fn get_hook_template_test() {
  write.get_hook_template(False)
  |> should.equal("#!/bin/sh \n\ngleam run --target erlang -m cactus -- ")

  write.get_hook_template(True)
  |> should.equal("#!/bin/sh \n\ngleam.exe run --target erlang -m cactus -- ")
}
