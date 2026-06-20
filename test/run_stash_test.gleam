import cactus/git
import filepath
import gleeunit/should
import shellout
import simplifile
import support/git_repo

const stash_config = "test/testdata/gleam/exec_stash.toml"

const stash_marker = ".stash-ran"

const pre_merge_marker = ".pre-merge-ran"

fn project_root() -> String {
  simplifile.current_directory()
  |> should.be_ok()
}

fn config_path(relative: String) -> String {
  filepath.join(project_root(), relative)
}

fn run_hook_in_repo(dir: String, hook: String) {
  shellout.command(
    run: "gleam",
    with: [
      "run",
      "-m",
      "cactus",
      "--",
      "--config",
      config_path(stash_config),
      hook,
    ],
    in: dir,
    opt: [],
  )
  |> should.be_ok()
}

pub fn pre_commit_stash_restore_test() {
  let _ = simplifile.delete(stash_marker)

  git_repo.with_temp_repo("pre_commit_stash", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "tracked.txt", "v1\n")

    let path = filepath.join(dir, "tracked.txt")
    let assert Ok(_) = simplifile.write(path, "v1\nunstaged\n")

    run_hook_in_repo(dir, "pre-commit")

    simplifile.file_info(filepath.join(dir, stash_marker))
    |> should.be_ok()

    simplifile.read(path)
    |> should.be_ok()
    |> should.equal("v1\nunstaged\n")
  })

  let _ = simplifile.delete(stash_marker)
}

pub fn pre_merge_commit_stash_restore_test() {
  let _ = simplifile.delete(pre_merge_marker)

  git_repo.with_temp_repo("pre_merge_stash", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "tracked.txt", "v1\n")

    let path = filepath.join(dir, "tracked.txt")
    let assert Ok(_) = simplifile.write(path, "v1\nunstaged\n")

    run_hook_in_repo(dir, "pre-merge-commit")

    simplifile.file_info(filepath.join(dir, pre_merge_marker))
    |> should.be_ok()

    simplifile.read(path)
    |> should.be_ok()
    |> should.equal("v1\nunstaged\n")
  })

  let _ = simplifile.delete(pre_merge_marker)
}

pub fn pop_stash_required_wrong_top_integration_test() {
  git_repo.with_temp_repo("stash_pop_wrong", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "tracked.txt", "v1\n")

    let path = filepath.join(dir, "tracked.txt")
    let assert Ok(_) = simplifile.write(path, "v1\nother\n")
    let assert Ok(_) =
      shellout.command(
        run: "git",
        with: ["stash", "push", "-m", "other-stash"],
        in: dir,
        opt: [],
      )

    git.pop_stash_required_in(dir)
    |> should.be_error()
    Nil
  })
}
