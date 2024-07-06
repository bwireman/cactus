#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

if [ -z "$1" ]; then
    echo "Must set target"
    echo "Usage: $0 <erlang|javascript>"
    exit 1
fi

TARGET="$1"
RUNTIME="$2"
if [ "$TARGET" = "erlang" ]; then
    CMD='--target erlang'
else
    if [ -z "$2" ]; then
        echo "Must set runtime"
        echo "Usage: $0 javascript <bun|nodejs|deno>"
        exit 1
    fi
    CMD="--target javascript --runtime $RUNTIME"
fi

function clean() {
    rm -rf .test-run
    rm -rf ".git/hooks/test"
}

clean
# shellcheck disable=SC2086
gleam test $CMD
# shellcheck disable=SC2086
gleam run $CMD

test -f ".git/hooks/test" || (echo "test: not found" && exit 1)
# shellcheck disable=SC2086
gleam run $CMD -- test

test -f ".test-run" || (echo ".test-run: not found" && exit 1)
clean
