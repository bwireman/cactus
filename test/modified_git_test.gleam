import cactus/modified.{All, Staged, Unstaged, get_files_for_scope_in}
import filepath
import gleam/list
import gleeunit/should
import shellout
import simplifile
import support/git_repo

pub fn staged_files_test() {
  git_repo.with_temp_repo("staged_scope", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "tracked.txt", "v1\n")

    let path = filepath.join(dir, "tracked.txt")
    let assert Ok(_) = simplifile.write(path, "v2\n")
    let assert Ok(_) =
      shellout.command(
        run: "git",
        with: ["add", "tracked.txt"],
        in: dir,
        opt: [],
      )

    get_files_for_scope_in(dir, Staged)
    |> should.equal(Ok(["tracked.txt"]))
  })
}

pub fn unstaged_files_test() {
  git_repo.with_temp_repo("unstaged_scope", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "tracked.txt", "v1\n")

    let path = filepath.join(dir, "tracked.txt")
    let assert Ok(_) = simplifile.write(path, "v2\n")
    let assert Ok(_) = simplifile.write(filepath.join(dir, "new.txt"), "new\n")

    get_files_for_scope_in(dir, Unstaged)
    |> should.be_ok()
    |> should.equal(["tracked.txt", "new.txt"])
  })
}

pub fn all_files_test() {
  git_repo.with_temp_repo("all_scope", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "tracked.txt", "v1\n")

    let path = filepath.join(dir, "tracked.txt")
    let assert Ok(_) = simplifile.write(path, "v2\n")
    let assert Ok(_) =
      shellout.command(
        run: "git",
        with: ["add", "tracked.txt"],
        in: dir,
        opt: [],
      )
    let assert Ok(_) = simplifile.write(filepath.join(dir, "new.txt"), "new\n")

    get_files_for_scope_in(dir, All)
    |> should.be_ok()
    |> list.contains("tracked.txt")
    |> should.be_true()

    get_files_for_scope_in(dir, All)
    |> should.be_ok()
    |> list.contains("new.txt")
    |> should.be_true()
  })
}
