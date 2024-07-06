#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

TARGET="$1"
RUNTIME="$2"
if [ "$TARGET" = "erlang" ]; then 
    CMD='--target erlang'    
else
    CMD="--target javascript --runtime $RUNTIME"    
fi

function clean() {
    rm -rf .test-run
    rm -rf ".git/hooks/test"
}

clean
gleam test $CMD
gleam run $CMD

test -f ".git/hooks/test" || (echo "test: not found" && exit 1)
gleam run $CMD -- test

test -f ".test-run" || (echo ".test-run: not found" && exit 1)
clean