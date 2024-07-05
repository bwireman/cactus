import cactus/run
import gleam/list
import gleeunit/should

pub fn parse_action_test() {
  // not present
  run.get_actions("test/testdata/gleam/basic.toml", "pre-commit")
  |> should.be_error

  let assert [a, b, c] =
    run.get_actions("test/testdata/gleam/basic.toml", "pre-push")
    |> should.be_ok
    |> list.map(run.parse_action)
    |> list.map(should.be_ok)

  should.equal(a.command, "A")
  should.equal(a.kind, run.SubCommand)
  should.equal(a.args, [])

  should.equal(b.command, "B")
  should.equal(b.kind, run.Module)
  should.equal(b.args, ["--outdated"])

  should.equal(c.command, "C")
  should.equal(c.kind, run.Binary)
  should.equal(c.args, [])

  run.get_actions("test/testdata/gleam/empty.toml", "")
  |> should.be_error

  run.get_actions("test/testdata/gleam/too_many.toml", "pre-merge-commit")
  |> should.be_ok
  |> should.equal([])

  run.get_actions("test/testdata/gleam/fake.toml", "")
  |> should.be_error
}
