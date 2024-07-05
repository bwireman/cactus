# 🌵 Cactus

[![Package Version](https://img.shields.io/hexpm/v/cactus)](https://hex.pm/packages/cactus)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cactus/)
[![mit](https://img.shields.io/github/license/bwireman/cactus?color=brightgreen)](https://github.com/bwireman/cactus/blob/main/LICENSE)
[![gleam js](https://img.shields.io/badge/%20gleam%20%E2%9C%A8-js%20%F0%9F%8C%B8-yellow)](https://gleam.run/news/v0.16-gleam-compiles-to-javascript/)
[![gleam erlang](https://img.shields.io/badge/erlang%20%E2%98%8E%EF%B8%8F-red?style=flat&label=gleam%20%E2%9C%A8)](https://gleam.run)

A tool for managing git lifecycle hooks with ✨ gleam!

# 🔽 Install

```sh
gleam add --dev cactus
```

#### 🌸 Javascript

Bun, Deno & Nodejs are _all_ supported!

# ▶️ Usage

**_FIRST_** configure hooks and then run

```sh
# initialize configured hooks
gleam run -m cactus
```

### ⚙️ Config

Optional settings that can be added to your project's `gleam.toml`

```toml
[cactus.pre-commit]
# list of actions for the hook
actions = [
    {
      # name of the command or binary to be run
      # required
      command = "format",
      # is it a gleam subcommand, a binary or a module
      # ["sub_command", "binary", "module"]
      # default: module
      kind = "sub_command",
      # additional args to be passed to the command
      # default: []
      args = ["--check"]
    },
]

[cactus.pre-push]
actions = [
    { command = "test", kind = "sub_command" },
    { command = "go_over", kind = "module", args=["--outdated"] },
]
```
