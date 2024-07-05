import cactus/util
import gleeunit/should

pub fn parse_gleam_toml_test() {
  util.parse_gleam_toml("test/testdata/gleam/basic.toml")
  |> should.be_ok

  util.parse_gleam_toml("test/testdata/gleam/empty.toml")
  |> should.be_ok

  util.parse_gleam_toml("test/testdata/gleam/too_many.toml")
  |> should.be_ok

  util.parse_gleam_toml("test/testdata/gleam/foo.toml")
  |> should.be_error
}
