import cactus/git
import cactus/util
import filepath
import gleeunit/should
import shellout
import simplifile

const git_work_dir = "test/testdata/git_work"

fn with_temp_repo(name: String, callback: fn(String) -> Nil) -> Nil {
  let dir = filepath.join(git_work_dir, name)
  let _ = simplifile.delete_all([dir])
  let _ = simplifile.create_directory(git_work_dir)
  let assert Ok(_) = simplifile.create_directory(dir)

  callback(dir)

  let _ = simplifile.delete_all([dir])
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
  let assert Ok(_) =
    shellout.command(
      run: "git",
      with: ["config", "core.autocrlf", "false"],
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

pub fn stash_unstaged_in_clean_repo_test() {
  with_temp_repo("clean_repo", fn(dir) {
    init_repo(dir)
    commit_file(dir, "file.txt", "tracked\n")

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(False))
  })
}

pub fn stash_unstaged_in_keeps_existing_stash_test() {
  with_temp_repo("existing_stash", fn(dir) {
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

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(False))
  })
}

pub fn stash_unstaged_in_stashes_unstaged_changes_test() {
  with_temp_repo("unstaged_changes", fn(dir) {
    init_repo(dir)
    commit_file(dir, "file.txt", "tracked\n")

    let path = filepath.join(dir, "file.txt")
    let assert Ok(_) = simplifile.write(path, "tracked\nunstaged\n")

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(True))

    let assert Ok(contents) = simplifile.read(path)
    util.normalize_newlines(contents) |> should.equal("tracked\n")

    let assert Ok(_) = git.pop_stash_in(dir)
    let assert Ok(contents) = simplifile.read(path)
    util.normalize_newlines(contents) |> should.equal("tracked\nunstaged\n")
  })
}

pub fn stash_unstaged_in_stashes_untracked_files_test() {
  with_temp_repo("untracked_files", fn(dir) {
    init_repo(dir)
    commit_file(dir, "file.txt", "tracked\n")

    let path = filepath.join(dir, "new.txt")
    let assert Ok(_) = simplifile.write(path, "untracked\n")

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(True))

    case simplifile.file_info(path) {
      Ok(_) -> should.fail()
      Error(_) -> Nil
    }

    let assert Ok(_) = git.pop_stash_in(dir)
    simplifile.file_info(path) |> should.be_ok()
    Nil
  })
}
