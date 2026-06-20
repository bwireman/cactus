import filepath
import gleeunit/should
import shellout.{SetEnvironment, command}
import simplifile
import support/git_repo

const filter_config = "test/testdata/gleam/exec_filter_run.toml"

const filter_marker = ".filter-ran"

fn project_root() -> String {
  simplifile.current_directory()
  |> should.be_ok()
}

fn config_path(relative: String) -> String {
  filepath.join(project_root(), relative)
}

fn run_hook_in_repo(
  dir: String,
  config: String,
  hook: String,
  env: List(#(String, String)),
) {
  command(
    run: "gleam",
    with: ["run", "-m", "cactus", "--", "--config", config, hook],
    in: dir,
    opt: [SetEnvironment(env)],
  )
  |> should.be_ok()
}

pub fn filtered_action_skipped_test() {
  let _ = simplifile.delete(filter_marker)

  git_repo.with_temp_repo("filter_run", fn(dir) {
    git_repo.init_repo(dir)
    git_repo.commit_file(dir, "readme.md", "hello\n")

    run_hook_in_repo(dir, config_path(filter_config), "pre-commit", [])

    case simplifile.file_info(filepath.join(dir, filter_marker)) {
      Ok(_) -> should.fail()
      Error(_) -> Nil
    }
  })

  let _ = simplifile.delete(filter_marker)
}
