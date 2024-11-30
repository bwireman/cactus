#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

gleam fix
gleam format
deno fmt