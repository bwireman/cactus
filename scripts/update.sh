#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

gleam update
gleam run -m go_over -- --outdated