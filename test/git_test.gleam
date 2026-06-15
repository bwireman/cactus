import cactus/git
import cactus/util
import filepath
import gleeunit/should
import shellout
import simplifile
import support/git_repo

pub fn stash_unstaged_in_clean_repo_test() {
  git_repo.with_temp_repo("clean_repo", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "file.txt", "tracked\n")

    git.stash_unstaged_in(dir)
    |> should.equal(Ok(False))
  })
}

pub fn stash_unstaged_in_keeps_existing_stash_test() {
  git_repo.with_temp_repo("existing_stash", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "file.txt", "tracked\n")

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
  git_repo.with_temp_repo("unstaged_changes", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "file.txt", "tracked\n")

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
  git_repo.with_temp_repo("untracked_files", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "file.txt", "tracked\n")

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
