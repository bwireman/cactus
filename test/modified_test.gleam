import cactus/modified.{matches_ending, modified_files_match}

pub fn matches_ending_test() {
  assert !matches_ending("foo", [])

  assert !matches_ending("foo", [".foo"])

  assert matches_ending(".foo", [".foo"])

  assert matches_ending(".foo", [".foo", ".bar", ".baz"])
}

pub fn modified_files_match_test() {
  assert modified_files_match(["foo"], ["./foo"])

  assert modified_files_match(["foo"], ["foo"])

  assert modified_files_match(["foo"], [])

  assert !modified_files_match(["foo"], ["bar"])

  assert modified_files_match([""], [])

  assert modified_files_match([], [""])

  assert modified_files_match([], [".foo", ".bar"])

  assert modified_files_match([], [])

  assert modified_files_match([""], [""])

  assert modified_files_match(["foo"], [""])

  assert !modified_files_match(["foo"], [".test"])

  assert modified_files_match(["foo.test"], ["bar.test", ".test"])

  assert modified_files_match(["foo.test"], ["./bar.test", ".test"])

  assert !modified_files_match(["foo.test"], ["./bar.test", ""])

  assert modified_files_match(["./bar.test"], [".test", "bar.test"])
}
