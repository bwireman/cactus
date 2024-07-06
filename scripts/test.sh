#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

GREEN='\033[0;32m'
NC='\033[0m'

gleam check
gleam update
gleam build
gleam format
rm -rf ".git/hooks/"
rm -rf .test-run

function assert_hooks() {
    test -f ".git/hooks/pre-commit" || (echo "pre-commit: not found" && exit 1)
    test -f ".git/hooks/pre-push" || (echo "pre-push: not found" && exit 1)
    test -f ".git/hooks/test" || (echo "test: not found" && exit 1)
}

echo -e "${GREEN}==> erlang${NC}"
gleam test --target erlang
gleam run --target erlang
assert_hooks
gleam run --target erlang -- test
./scripts/assert_test.sh
rm -rf ".git/hooks/"

echo -e "${GREEN}==> nodejs${NC}"
gleam test --target javascript --runtime nodejs
gleam run --target javascript --runtime nodejs
assert_hooks
gleam run --target javascript --runtime nodejs -- test
./scripts/assert_test.sh
rm -rf ".git/hooks/"

echo -e "${GREEN}==> deno${NC}"
gleam test --target javascript --runtime deno
gleam run --target javascript --runtime deno
assert_hooks
gleam run --target javascript --runtime deno -- test
./scripts/assert_test.sh
rm -rf ".git/hooks/"

echo -e "${GREEN}==> bun${NC}"
gleam test --target javascript --runtime bun
gleam run --target javascript --runtime bun
assert_hooks
gleam run --target javascript --runtime bun -- test
./scripts/assert_test.sh

gleam run