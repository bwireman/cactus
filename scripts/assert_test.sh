#!/usr/bin/env bash
set -e

test -f ".test-run" || (echo ".test-run: not found" && exit 1)
rm -rf .test-run
