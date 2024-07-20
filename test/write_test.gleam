import cactus/write
import filepath
import gleam/list
import gleeunit/should
import simplifile

const hook_dir = "test/testdata/scripts"

const node_files = [
  "./gleam.toml", "test/testdata/gleam/basic.toml",
  "test/testdata/gleam/empty.toml", "foo/bar/baz",
  "test/testdata/gleam/node.toml", "test/testdata/gleam/junk.toml",
]

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
  node_files
  |> list.map(write.tmpl)
  |> list.each(should.equal(
    _,
    "gleam run --target javascript --runtime nodejs -m cactus -- ",
  ))

  write.tmpl("test/testdata/gleam/bun.toml")
  |> should.equal("gleam run --target javascript --runtime bun -m cactus -- ")

  write.tmpl("test/testdata/gleam/deno.toml")
  |> should.equal("gleam run --target javascript --runtime deno -m cactus -- ")
}

@target(erlang)
pub fn template_test() {
  [
    "test/testdata/gleam/bun.toml",
    "test/testdata/gleam/deno.toml",
    ..node_files
  ]
  |> list.map(write.tmpl)
  |> list.each(should.equal(_, "gleam run --target erlang -m cactus -- "))
}
