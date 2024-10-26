import cactus/modified.{matches_ending, modfied_files_match}
import gleeunit/should

pub fn matches_ending_test() {
  matches_ending("foo", [])
  |> should.be_false()

  matches_ending("foo", [".foo"])
  |> should.be_false()

  matches_ending(".foo", [".foo"])
  |> should.be_true()

  matches_ending(".foo", [".foo", ".bar", ".baz"])
  |> should.be_true()
}

pub fn modfied_files_match_test() {
  modfied_files_match(["foo"], ["./foo"])
  |> should.be_true()

  modfied_files_match(["foo"], ["foo"])
  |> should.be_true()

  modfied_files_match(["foo"], [])
  |> should.be_true()

  modfied_files_match(["foo"], ["bar"])
  |> should.be_false()

  modfied_files_match([""], [])
  |> should.be_true()

  modfied_files_match([], [""])
  |> should.be_true()

  modfied_files_match([], [".foo", ".bar"])
  |> should.be_true()

  modfied_files_match([], [])
  |> should.be_true()

  modfied_files_match([""], [""])
  |> should.be_true()

  modfied_files_match(["foo"], [""])
  |> should.be_true()

  modfied_files_match(["foo"], [".test"])
  |> should.be_false()

  modfied_files_match(["foo.test"], ["bar.test", ".test"])
  |> should.be_true()

  modfied_files_match(["foo.test"], ["./bar.test", ".test"])
  |> should.be_true()

  modfied_files_match(["foo.test"], ["./bar.test", ""])
  |> should.be_false()

  modfied_files_match(["./bar.test"], [".test", "bar.test"])
  |> should.be_true()
}
