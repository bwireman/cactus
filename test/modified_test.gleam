import cactus/modified.{
  All, Staged, Unstaged, file_matches_pattern, modified_files_match,
  parse_files_scope,
}
import gleeunit/should

pub fn extension_match_test() {
  file_matches_pattern("src/foo.gleam", ".gleam")
  |> should.be_true()

  file_matches_pattern("foo", ".foo")
  |> should.be_false()

  file_matches_pattern(".foo", ".foo")
  |> should.be_true()
}

pub fn modified_files_match_test() {
  modified_files_match(["foo"], ["./foo"])
  |> should.be_true()

  modified_files_match(["foo"], ["foo"])
  |> should.be_true()

  modified_files_match(["foo"], [])
  |> should.be_true()

  modified_files_match(["foo"], ["bar"])
  |> should.be_false()

  modified_files_match([""], [])
  |> should.be_true()

  modified_files_match([], [""])
  |> should.be_true()

  modified_files_match([], [".foo", ".bar"])
  |> should.be_false()

  modified_files_match([], [])
  |> should.be_true()

  modified_files_match([""], [""])
  |> should.be_true()

  modified_files_match(["foo"], [""])
  |> should.be_true()

  modified_files_match(["foo"], [".test"])
  |> should.be_false()

  modified_files_match(["foo.test"], ["bar.test", ".test"])
  |> should.be_true()

  modified_files_match(["foo.test"], ["./bar.test", ".test"])
  |> should.be_true()

  modified_files_match(["foo.test"], ["./bar.test", ""])
  |> should.be_false()

  modified_files_match(["./bar.test"], [".test", "bar.test"])
  |> should.be_true()
}

pub fn glob_match_src_root_test() {
  file_matches_pattern("src/foo.gleam", "src/**/*.gleam")
  |> should.be_true()
}

pub fn glob_match_src_nested_test() {
  file_matches_pattern("src/nested/foo.gleam", "src/**/*.gleam")
  |> should.be_true()
}

pub fn glob_match_src_negative_test() {
  file_matches_pattern("test/foo.gleam", "src/**/*.gleam")
  |> should.be_false()
}

pub fn glob_match_extension_test() {
  file_matches_pattern("src/foo.gleam", "*.gleam")
  |> should.be_true()
}

pub fn parse_files_scope_test() {
  parse_files_scope("staged")
  |> should.be_ok()
  |> should.equal(Staged)

  parse_files_scope("ALL")
  |> should.be_ok()
  |> should.equal(All)

  parse_files_scope("unstaged")
  |> should.be_ok()
  |> should.equal(Unstaged)

  parse_files_scope("nope")
  |> should.be_error()
}
