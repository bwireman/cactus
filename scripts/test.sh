#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

GREEN='\033[0;32m'
NC='\033[0m'

gleam check
gleam build
gleam format

echo -e "${GREEN}==> erlang${NC}"
./scripts/target_test.sh erlang

echo -e "${GREEN}==> nodejs${NC}"
./scripts/target_test.sh javascript nodejs

echo -e "${GREEN}==> deno${NC}"
./scripts/target_test.sh javascript deno

echo -e "${GREEN}==> bun${NC}"
./scripts/target_test.sh javascript bun

gleam run