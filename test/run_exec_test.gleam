import cactus/run
import cactus/write
import gleam/option.{Some}
import gleeunit/should
import shellout.{SetEnvironment, command}
import simplifile

const exec_config = "test/testdata/gleam/exec.toml"

const exec_skip_config = "test/testdata/gleam/exec_skip.toml"

const exec_skip_env_config = "test/testdata/gleam/exec_skip_env.toml"

const exec_env_config = "test/testdata/gleam/exec_env.toml"

const exec_continue_config = "test/testdata/gleam/exec_continue.toml"

const exec_filter_config = "test/testdata/gleam/exec_filter.toml"

const invalid_skip_config = "test/testdata/gleam/invalid_skip.toml"

const continue_marker = ".continue-ran"

const skip_ci_marker = ".skip-ci-ran"

const skip_env_marker = ".skip-env-ran"

fn run_hook_with_env(
  config: String,
  hook: String,
  env: List(#(String, String)),
) {
  command(
    run: "gleam",
    with: ["run", "-m", "cactus", "--", "--config", config, hook],
    in: ".",
    opt: [SetEnvironment(env)],
  )
  |> should.be_ok()
}

pub fn dry_run_test() {
  run.run(exec_config, "test", run.RunOptions(verbose: False, dry_run: True))
  |> should.be_ok()
}

pub fn hook_config_test() {
  run.get_hook_config(exec_filter_config, "pre-commit")
  |> should.be_ok()
}

pub fn skip_env_config_test() {
  let assert Ok(config) = run.get_hook_config(exec_skip_config, "test")
  case config.skip_env {
    Some("CI=true") -> Nil
    _ -> should.fail()
  }
}

pub fn invalid_skip_env_test() {
  run.get_hook_config(invalid_skip_config, "test")
  |> should.be_error()
}

pub fn skip_env_ci_runtime_test() {
  let _ = simplifile.delete(skip_ci_marker)

  run_hook_with_env(exec_skip_config, "test", [#("CI", "true")])

  case simplifile.file_info(skip_ci_marker) {
    Ok(_) -> should.fail()
    Error(_) -> Nil
  }
}

pub fn skip_env_runtime_test() {
  let _ = simplifile.delete(skip_env_marker)

  run_hook_with_env(exec_skip_env_config, "test", [#("SKIP_HOOKS", "1")])

  case simplifile.file_info(skip_env_marker) {
    Ok(_) -> should.fail()
    Error(_) -> Nil
  }
}

pub fn env_runtime_test() {
  run.run(
    exec_env_config,
    "test",
    run.RunOptions(verbose: False, dry_run: False),
  )
  |> should.be_ok()
}

pub fn on_failure_continue_test() {
  let _ = simplifile.delete(continue_marker)

  run.run(
    exec_continue_config,
    "test",
    run.RunOptions(verbose: False, dry_run: False),
  )
  |> should.be_error()

  simplifile.file_info(continue_marker)
  |> should.be_ok()

  let _ = simplifile.delete(continue_marker)
}

pub fn is_valid_hook_name_test() {
  write.is_valid_hook_name("post-commit")
  |> should.be_true()

  write.is_valid_hook_name("not-a-hook")
  |> should.be_false()
}

pub fn is_cactus_hook_test() {
  write.is_cactus_hook(
    "#!/bin/sh\n\ngleam run --target erlang -m cactus -- pre-commit",
  )
  |> should.be_true()

  write.is_cactus_hook("#!/bin/sh\n\necho hello")
  |> should.be_false()
}
