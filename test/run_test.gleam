import cactus/run
import gleam/list
import gleeunit/should

fn parse(file: String, action: String) {
  run.get_actions(file, action)
  |> should.be_ok()
  |> list.map(run.parse_action)
}

pub fn parse_action_test() {
  // not present
  let assert Error(_) =
    run.get_actions("test/testdata/gleam/basic.toml", "pre-commit")

  // not present
  let assert Error(_) =
    run.get_actions("test/testdata/gleam/dos.toml", "pre-commit")

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

  let assert [dos_a, dos_b, dos_c] =
    parse("test/testdata/gleam/dos.toml", "pre-push")
    |> list.map(should.be_ok)
  should.equal(dos_a.command, "A")
  should.equal(dos_a.kind, run.SubCommand)
  should.equal(dos_a.args, [])

  should.equal(dos_b.command, "B")
  should.equal(dos_b.kind, run.Module)
  should.equal(dos_b.args, ["--outdated"])

  should.equal(dos_c.command, "C")
  should.equal(dos_c.kind, run.Binary)
  should.equal(dos_c.args, [])

  let assert Error(_) = run.get_actions("test/testdata/gleam/empty.toml", "")

  let assert Error(_) =
    run.get_actions("test/testdata/gleam/invalid.toml", "no-actions")

  let assert Error(_) =
    run.get_actions("test/testdata/gleam/invalid.toml", "actions-wrong-type")

  parse("test/testdata/gleam/invalid.toml", "actions-element-wrong-type")
  |> list.map(should.be_error)

  parse("test/testdata/gleam/invalid.toml", "no-command")
  |> list.map(should.be_error)

  parse("test/testdata/gleam/invalid.toml", "kind-wrong-type")
  |> list.map(should.be_error)

  let assert Ok([]) =
    run.get_actions("test/testdata/gleam/too_many.toml", "pre-merge-commit")

  let assert Error(_) = run.get_actions("test/testdata/gleam/fake.toml", "")
}
