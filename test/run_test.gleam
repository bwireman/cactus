import cactus/run
import gleam/list
import gleeunit/should

fn parse(file: String, action: String) {
  run.get_actions(file, action)
  |> should.be_ok
  |> list.map(run.parse_action)
}

pub fn parse_action_test() {
  // not present
  run.get_actions("test/testdata/gleam/basic.toml", "pre-commit")
  |> should.be_error()

  let assert [a, b, c] =
    parse("test/testdata/gleam/basic.toml", "pre-push")
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

  run.get_actions("test/testdata/gleam/invalid.toml", "no-actions")
  |> should.be_error

  run.get_actions("test/testdata/gleam/invalid.toml", "actions-wrong-type")
  |> should.be_error()

  parse("test/testdata/gleam/invalid.toml", "actions-element-wrong-type")
  |> list.map(should.be_error)

  parse("test/testdata/gleam/invalid.toml", "no-command")
  |> list.map(should.be_error)

  parse("test/testdata/gleam/invalid.toml", "kind-wrong-type")
  |> list.map(should.be_error)

  run.get_actions("test/testdata/gleam/too_many.toml", "pre-merge-commit")
  |> should.be_ok
  |> should.equal([])

  run.get_actions("test/testdata/gleam/fake.toml", "")
  |> should.be_error
}
