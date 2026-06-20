import cactus/run
import cactus/write
import gleam/option.{Some}
import gleeunit/should
import simplifile

const exec_config = "test/testdata/gleam/exec.toml"

const exec_skip_config = "test/testdata/gleam/exec_skip.toml"

const exec_continue_config = "test/testdata/gleam/exec_continue.toml"

const exec_filter_config = "test/testdata/gleam/exec_filter.toml"

const continue_marker = ".continue-ran"

pub fn dry_run_test() {
  run.run(exec_config, "test", run.RunOptions(verbose: False, dry_run: True))
  |> should.be_ok()
}

pub fn hook_config_test() {
  run.get_hook_config(exec_filter_config, "pre-commit")
  |> should.be_ok()
}

pub fn skip_if_config_test() {
  let assert Ok(config) = run.get_hook_config(exec_skip_config, "test")
  case config.skip_if {
    Some("ci") -> Nil
    _ -> should.fail()
  }
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
