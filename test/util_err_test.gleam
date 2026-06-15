import cactus/util.{
  ActionFailedErr, CLIErr, FSErr, GitError, InvalidFieldErr, InvalidTomlErr,
  err_as_str, quote,
}
import gleeunit/should
import gleither.{Left, Right}
import simplifile
import tom.{NotFound}

pub fn err_as_str_test() {
  err_as_str(InvalidTomlErr)
  |> should.equal("Invalid Toml Error")

  err_as_str(InvalidFieldErr("", Left(NotFound(["cactus", "actions"]))))
  |> should.equal("Missing field in config: " <> quote("cactus.actions"))

  err_as_str(InvalidFieldErr("kind", Right("got: 'foo' expected: module")))
  |> should.equal("Invalid field in config: kind got: 'foo' expected: module")

  err_as_str(ActionFailedErr(2, 5, "format --check", "bad fmt"))
  |> should.equal("Action 2/5 failed: 'format --check'\nbad fmt")

  err_as_str(CLIErr("nope"))
  |> should.equal("CLI Error: invalid arg 'nope'")

  err_as_str(GitError("git stash pop", "conflict"))
  |> should.equal("Error while running 'git stash pop' : 'conflict'")

  err_as_str(FSErr("path", simplifile.Eacces))
  |> should.equal("FS Error at path with Permission denied")
}
