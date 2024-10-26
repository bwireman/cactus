# 🌵 Cactus

[![Package Version](https://img.shields.io/hexpm/v/cactus)](https://hex.pm/packages/cactus)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cactus/)
[![mit](https://img.shields.io/github/license/bwireman/cactus?color=brightgreen)](https://github.com/bwireman/cactus/blob/main/LICENSE)
[![gleam js](https://img.shields.io/badge/%20gleam%20%E2%9C%A8-js%20%F0%9F%8C%B8-yellow)](https://gleam.run/news/v0.16-gleam-compiles-to-javascript/)
[![gleam erlang](https://img.shields.io/badge/erlang%20%E2%98%8E%EF%B8%8F-red?style=flat&label=gleam%20%E2%9C%A8)](https://gleam.run)

A tool for managing git lifecycle hooks with ✨ gleam! Pre commit, Pre push and more!

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
# specify the target depending on how you want the hooks to run
gleam run --target <javascript|erlang> -m cactus
```

### ⚙️ Config

Settings that can be added to your project's `gleam.toml`

```toml
[cactus]
# init hooks on every run (default: false)
always_init = false

# hook name (all git hooks are supported)
[cactus.pre-commit]
# list of actions for the hook
actions = [
    # command: name of the command or binary to be run: required
    # kind: is it a gleam subcommand, a binary or a module: ["sub_command", "binary", "module"], default: module
    # args: additional args to be passed to the command, default: []
    { command = "format", kind = "sub_command", args = ["--check"] },
    { command = "./scripts/test.sh", kind = "binary" },
]
```
