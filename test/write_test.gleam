import cactus/write
import filepath
import gleam/list
import gleeunit/should
@target(javascript)
import platform
import simplifile

const hook_dir = "test/testdata/scripts"

pub fn init_test() {
  simplifile.delete_all([hook_dir])
  |> should.be_ok()

  write.init(hook_dir, "test/testdata/gleam/too_many.toml", False)
  |> should.be_ok()
  |> list.length()
  |> should.equal(13)
}

pub fn create_script_test() {
  simplifile.delete_all([filepath.join(hook_dir, "test"), hook_dir])
  |> should.be_ok()

  write.create_script("test/testdata/scripts", "test", False)
  |> should.be_ok()

  simplifile.read("test/testdata/scripts/test")
  |> should.be_ok()
  |> should.equal(write.get_hook_template(False) <> "test")
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
