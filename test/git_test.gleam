import cactus/git
import cactus/util
import filepath
import gleam/string
import gleeunit/should
import shellout
import simplifile

fn with_temp_repo(callback: fn(String) -> Nil) -> Nil {
  let assert Ok(tmp_raw) =
    shellout.command(run: "mktemp", with: ["-d"], in: ".", opt: [])
  let tmp = string.trim(tmp_raw)

  callback(tmp)

  let assert Ok(_) =
    shellout.command(run: "rm", with: ["-rf", tmp], in: ".", opt: [])
  Nil
}

fn init_repo(dir: String) -> Nil {
  let assert Ok(_) =
    shellout.command(run: "git", with: ["init", "-q"], in: dir, opt: [])
  let assert Ok(_) =
    shellout.command(
      run: "git",
      with: ["config", "user.email", "cactus@test"],
      in: dir,
      opt: [],
    )
  let assert Ok(_) =
    shellout.command(
      run: "git",
      with: ["config", "user.name", "cactus"],
      in: dir,
      opt: [],
    )
  Nil
}

fn commit_file(dir: String, name: String, content: String) -> Nil {
  let path = filepath.join(dir, name)
  let assert Ok(_) = simplifile.write(path, content)
  let assert Ok(_) =
    shellout.command(run: "git", with: ["add", name], in: dir, opt: [])
  let assert Ok(_) =
    shellout.command(
      run: "git",
      with: ["commit", "-q", "-m", "init"],
      in: dir,
      opt: [],
    )
  Nil
}

fn file_exists(path: String) -> Bool {
  case simplifile.file_info(path) {
    Ok(_) -> True
    Error(_) -> False
  }
}

pub fn no_changes_to_stash_test() {
  git.no_changes_to_stash(util.GitError(
    "git stash push",
    "No local changes to save",
  ))
  |> should.equal(Ok(False))

  git.no_changes_to_stash(util.GitError(
    "git stash push",
    "fatal: not a git repo",
  ))
  |> should.be_error()
}

pub fn stash_unstaged_in_clean_repo_test() {
  with_temp_repo(fn(dir) {
    init_repo(dir)
    commit_file(dir, "file.txt", "tracked\n")

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(False))

    git.stash_list_length(dir)
    |> should.equal(Ok(0))
  })
}

pub fn stash_unstaged_in_keeps_existing_stash_test() {
  with_temp_repo(fn(dir) {
    init_repo(dir)
    commit_file(dir, "file.txt", "tracked\n")

    let path = filepath.join(dir, "file.txt")
    let assert Ok(_) = simplifile.write(path, "tracked\nexisting stash\n")
    let assert Ok(_) =
      shellout.command(
        run: "git",
        with: ["stash", "push", "-q"],
        in: dir,
        opt: [],
      )
    let assert Ok(_) =
      shellout.command(
        run: "git",
        with: ["restore", "file.txt"],
        in: dir,
        opt: [],
      )

    git.stash_list_length(dir)
    |> should.equal(Ok(1))

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(False))

    git.stash_list_length(dir)
    |> should.equal(Ok(1))
  })
}

pub fn stash_unstaged_in_stashes_unstaged_changes_test() {
  with_temp_repo(fn(dir) {
    init_repo(dir)
    commit_file(dir, "file.txt", "tracked\n")

    let path = filepath.join(dir, "file.txt")
    let assert Ok(_) = simplifile.write(path, "tracked\nunstaged\n")

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(True))

    git.stash_list_length(dir)
    |> should.equal(Ok(1))

    let assert Ok(contents) = simplifile.read(path)
    should.equal(contents, "tracked\n")

    let assert Ok(_) = git.pop_stash_in(dir)
    let assert Ok(contents) = simplifile.read(path)
    should.equal(contents, "tracked\nunstaged\n")
  })
}

pub fn stash_unstaged_in_stashes_untracked_files_test() {
  with_temp_repo(fn(dir) {
    init_repo(dir)
    commit_file(dir, "file.txt", "tracked\n")

    let path = filepath.join(dir, "new.txt")
    let assert Ok(_) = simplifile.write(path, "untracked\n")

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(True))

    should.equal(file_exists(path), False)

    let assert Ok(_) = git.pop_stash_in(dir)
    should.equal(file_exists(path), True)
  })
}
