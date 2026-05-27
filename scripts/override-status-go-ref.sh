#!/usr/bin/env bash
# Override vendor/status-go submodule to given ref (SHA, branch, or PR head).
set -euo pipefail

REF="${1:?Usage: $(basename "$0") <status-go-ref>}"

cd vendor/status-go
git fetch --no-tags origin \
  '+refs/heads/*:refs/remotes/origin/*' \
  '+refs/pull/*/head:refs/remotes/origin/pr/*'
git checkout --detach "${REF}"
git submodule update --init --recursive
