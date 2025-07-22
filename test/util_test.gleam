import cactus/util
import gleeunit/should

pub fn parse_gleam_toml_test() {
  util.parse_gleam_toml("test/testdata/gleam/basic.toml")
  |> should.be_ok()

  util.parse_gleam_toml("test/testdata/gleam/empty.toml")
  |> should.be_ok()

  util.parse_gleam_toml("test/testdata/gleam/too_many.toml")
  |> should.be_ok()

  util.parse_gleam_toml("test/testdata/gleam/foo.toml")
  |> should.be_error()
}

pub fn parse_always_init_test() {
  assert !util.parse_always_init("test/testdata/gleam/basic.toml")

  assert !util.parse_always_init("test/testdata/gleam/basic.toml")

  assert !util.parse_always_init("test/testdata/gleam/too_many.toml")

  assert !util.parse_always_init("test/testdata/gleam/foo.toml")

  assert util.parse_always_init("test/testdata/gleam/always.toml")
}

pub fn drop_empty_test() {
  util.drop_empty([])
  |> should.equal([])

  util.drop_empty([""])
  |> should.equal([])

  util.drop_empty(["foo"])
  |> should.equal(["foo"])

  util.drop_empty(["", "", "foo", ""])
  |> should.equal(["foo"])
}
