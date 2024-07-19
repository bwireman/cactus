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

  write.create_script("test/testdata/scripts", "test")
  |> should.be_ok

  simplifile.read("test/testdata/scripts/test")
  |> should.be_ok
  |> should.equal(write.tmpl() <> "test")
}
