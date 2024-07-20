import cactus/write
import filepath
import gleam/list
import gleeunit/should
import simplifile

const hook_dir = "test/testdata/scripts"

pub fn init_test() {
  simplifile.delete_all([hook_dir])
  |> should.be_ok

  write.init(hook_dir, "test/testdata/gleam/too_many.toml")
  |> should.be_ok
  |> list.length
  |> should.equal(13)
}

pub fn create_script_test() {
  simplifile.delete_all([filepath.join(hook_dir, "test"), hook_dir])
  |> should.be_ok

  write.create_script("test/testdata/scripts", "", "test")
  |> should.be_ok

  simplifile.read("test/testdata/scripts/test")
  |> should.be_ok
  |> should.equal(write.tmpl("./gleam.toml") <> "test")
}

@target(javascript)
pub fn template_test() {
  write.tmpl("./gleam.toml")
  |> should.equal(
    "gleam run --target javascript --runtime nodejs -m cactus -- ",
  )

  write.tmpl("test/testdata/gleam/basic.toml")
  |> should.equal(
    "gleam run --target javascript --runtime nodejs -m cactus -- ",
  )

  write.tmpl("test/testdata/gleam/empty.toml")
  |> should.equal(
    "gleam run --target javascript --runtime nodejs -m cactus -- ",
  )

  write.tmpl("foo/bar/baz")
  |> should.equal(
    "gleam run --target javascript --runtime nodejs -m cactus -- ",
  )

  write.tmpl("test/testdata/gleam/node.toml")
  |> should.equal(
    "gleam run --target javascript --runtime nodejs -m cactus -- ",
  )

  write.tmpl("test/testdata/gleam/bun.toml")
  |> should.equal("gleam run --target javascript --runtime bun -m cactus -- ")

  write.tmpl("test/testdata/gleam/deno.toml")
  |> should.equal("gleam run --target javascript --runtime deno -m cactus -- ")

  write.tmpl("test/testdata/gleam/junk.toml")
  |> should.equal(
    "gleam run --target javascript --runtime nodejs -m cactus -- ",
  )
}
