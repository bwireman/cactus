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
  |> should.be_ok()

  write.init(hook_dir, "test/testdata/gleam/too_many.toml", False)
  |> should.be_ok()
  |> list.length
  |> should.equal(13)
}

pub fn create_script_test() {
  simplifile.delete_all([filepath.join(hook_dir, "test"), hook_dir])
  |> should.be_ok()

  write.create_script("test/testdata/scripts", "", "test", False)
  |> should.be_ok()

  simplifile.read("test/testdata/scripts/test")
  |> should.be_ok()
  |> should.equal(write.get_hook_template("./gleam.toml", False) <> "test")
}

@target(javascript)
pub fn get_hook_template_test() {
  node_files
  |> list.map(write.get_hook_template(_, False))
  |> list.each(should.equal(
    _,
    "#!/bin/sh \n\ngleam run --target javascript --runtime nodejs -m cactus -- ",
  ))

  write.get_hook_template("test/testdata/gleam/bun.toml", False)
  |> should.equal(
    "#!/bin/sh \n\ngleam run --target javascript --runtime bun -m cactus -- ",
  )

  write.get_hook_template("test/testdata/gleam/deno.toml", False)
  |> should.equal(
    "#!/bin/sh \n\ngleam run --target javascript --runtime deno -m cactus -- ",
  )
}

@target(erlang)
pub fn get_hook_template_test() {
  [
    "test/testdata/gleam/bun.toml",
    "test/testdata/gleam/deno.toml",
    ..node_files
  ]
  |> list.map(write.get_hook_template(_, False))
  |> list.each(should.equal(
    _,
    "#!/bin/sh \n\ngleam run --target erlang -m cactus -- ",
  ))
}
