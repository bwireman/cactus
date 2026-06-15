import cactus/run
import cactus/write
import gleeunit/should

const exec_config = "test/testdata/gleam/exec.toml"

pub fn dry_run_test() {
  run.run(
    exec_config,
    "test-dry",
    run.RunOptions(verbose: False, dry_run: True),
  )
  |> should.be_ok()
}

pub fn invalid_hook_config_test() {
  run.get_hook_config(exec_config, "test-hook")
  |> should.be_ok()
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
