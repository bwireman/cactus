import filepath
import shellout
import simplifile

const git_work_dir = "test/testdata/git_work"

pub fn with_temp_repo(name: String, callback: fn(String) -> Nil) -> Nil {
  let dir = filepath.join(git_work_dir, name)
  let _ = simplifile.delete_all([dir])
  let _ = simplifile.create_directory(git_work_dir)
  let assert Ok(_) = simplifile.create_directory(dir)

  callback(dir)

  let _ = simplifile.delete_all([dir])
  Nil
}

pub fn init_repo(dir: String) -> Nil {
  let assert Ok(_) =
    shellout.command(run: "git", with: ["init", "-q"], in: dir, opt: [])
  let assert Ok(_) =
    shellout.command(
      run: "git",
      with: ["config", "user.email", "cactus@test"],
      in: dir,
      opt: [],
    )
  let assert Ok(_) =
    shellout.command(
      run: "git",
      with: ["config", "user.name", "cactus"],
      in: dir,
      opt: [],
    )
  let assert Ok(_) =
    shellout.command(
      run: "git",
      with: ["config", "core.autocrlf", "false"],
      in: dir,
      opt: [],
    )
  Nil
}

pub fn commit_file(dir: String, name: String, content: String) -> Nil {
  let path = filepath.join(dir, name)
  let assert Ok(_) = simplifile.write(path, content)
  let assert Ok(_) =
    shellout.command(run: "git", with: ["add", name], in: dir, opt: [])
  let assert Ok(_) =
    shellout.command(
      run: "git",
      with: ["commit", "-q", "-m", "init"],
      in: dir,
      opt: [],
    )
  Nil
}
