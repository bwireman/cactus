import cactus/cli
import cactus/run
import gleam/option
import gleeunit/should

pub fn parse_args_test() {
  cli.parse_args(["--verbose", "init"])
  |> should.equal(cli.CliOptions(
    verbose: True,
    dry_run: False,
    config_path: option.None,
    command: "init",
  ))

  cli.parse_args(["--dry-run", "pre-commit"])
  |> should.equal(cli.CliOptions(
    verbose: False,
    dry_run: True,
    config_path: option.None,
    command: "pre-commit",
  ))

  cli.parse_args(["--config", "other.toml", "init"])
  |> should.equal(cli.CliOptions(
    verbose: False,
    dry_run: False,
    config_path: option.Some("other.toml"),
    command: "init",
  ))
}

pub fn to_run_options_test() {
  cli.to_run_options(cli.CliOptions(
    verbose: True,
    dry_run: True,
    config_path: option.None,
    command: "init",
  ))
  |> should.equal(run.RunOptions(verbose: True, dry_run: True))
}

pub fn resolve_config_path_test() {
  cli.resolve_config_path(
    cli.CliOptions(
      verbose: False,
      dry_run: False,
      config_path: option.None,
      command: "",
    ),
    "/tmp/project",
  )
  |> should.equal("/tmp/project/gleam.toml")

  cli.resolve_config_path(
    cli.CliOptions(
      verbose: False,
      dry_run: False,
      config_path: option.Some("cfg/gleam.toml"),
      command: "",
    ),
    "/tmp/project",
  )
  |> should.equal("/tmp/project/cfg/gleam.toml")
}

pub fn help_aliases_test() {
  cli.parse_args(["--help"])
  |> should.equal(cli.CliOptions(
    verbose: False,
    dry_run: False,
    config_path: option.None,
    command: "help",
  ))

  cli.parse_args(["-h", "init"])
  |> should.equal(cli.CliOptions(
    verbose: False,
    dry_run: False,
    config_path: option.None,
    command: "help",
  ))
}

pub fn resolve_config_absolute_path_test() {
  cli.resolve_config_path(
    cli.CliOptions(
      verbose: False,
      dry_run: False,
      config_path: option.Some("/etc/gleam.toml"),
      command: "",
    ),
    "/tmp/project",
  )
  |> should.equal("/etc/gleam.toml")
}

pub fn resolve_config_windows_drive_path_test() {
  cli.resolve_config_path(
    cli.CliOptions(
      verbose: False,
      dry_run: False,
      config_path: option.Some(
        "D:/a/cactus/test/testdata/gleam/exec_stash.toml",
      ),
      command: "",
    ),
    "D:\\a\\cactus\\test\\testdata\\git_work\\pre_commit_stash",
  )
  |> should.equal("D:/a/cactus/test/testdata/gleam/exec_stash.toml")
}
