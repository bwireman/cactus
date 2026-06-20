import filepath
import gleeunit/should
import shellout
import simplifile
import support/git_repo

const cwd_config = "test/testdata/gleam/exec_cwd_filter.toml"

const cwd_marker = "pkg/.cwd-filter-ran"

fn project_root() -> String {
  simplifile.current_directory()
  |> should.be_ok()
}

fn config_path(relative: String) -> String {
  filepath.join(project_root(), relative)
}

pub fn cwd_scoped_file_filter_test() {
  let _ = simplifile.delete("pkg/.cwd-filter-ran")

  git_repo.with_temp_repo("cwd_filter", fn(dir) {
    git_repo.init_repo(dir)
    let outside_file = filepath.join(dir, "outside.txt")
    let assert Ok(_) = simplifile.write(outside_file, "outside\n")
    let assert Ok(_) =
      shellout.command(
        run: "git",
        with: ["add", "outside.txt"],
        in: dir,
        opt: [],
      )
    let assert Ok(_) =
      shellout.command(
        run: "git",
        with: ["commit", "-q", "-m", "outside"],
        in: dir,
        opt: [],
      )

    let pkg_dir = filepath.join(dir, "pkg")
    let assert Ok(_) = simplifile.create_directory(pkg_dir)
    let pkg_file = filepath.join(pkg_dir, "inside.txt")
    let assert Ok(_) = simplifile.write(pkg_file, "inside\n")

    shellout.command(
      run: "gleam",
      with: [
        "run",
        "-m",
        "cactus",
        "--",
        "--config",
        config_path(cwd_config),
        "pre-commit",
      ],
      in: dir,
      opt: [],
    )
    |> should.be_ok()

    case simplifile.file_info(filepath.join(dir, cwd_marker)) {
      Ok(_) -> should.fail()
      Error(_) -> Nil
    }

    let assert Ok(_) =
      shellout.command(
        run: "git",
        with: ["add", "pkg/inside.txt"],
        in: dir,
        opt: [],
      )

    shellout.command(
      run: "gleam",
      with: [
        "run",
        "-m",
        "cactus",
        "--",
        "--config",
        config_path(cwd_config),
        "pre-commit",
      ],
      in: dir,
      opt: [],
    )
    |> should.be_ok()

    let assert Ok(_) = simplifile.file_info(filepath.join(dir, cwd_marker))
    Nil
  })

  let _ = simplifile.delete("pkg/.cwd-filter-ran")
}
