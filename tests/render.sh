#!/usr/bin/env bash
# Render each stack (or the ones named) into a scratch repo and run its own gates.
# PROJECT_SETUP may point at project-setup's project_setup.py to add its verify.
set -euo pipefail
template="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stacks=("$@")
[ ${#stacks[@]} -gt 0 ] || mapfile -t stacks < <(sed -n 's/^    .*: \([a-z][a-z0-9-]*\)$/\1/p' "$template/copier.yml")
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
for stack in "${stacks[@]}"; do
  echo "== $stack"
  copier copy --quiet --defaults --trust --vcs-ref HEAD \
    --data stack="$stack" --data description="Render test" "$template" "$work/$stack-demo"
  (
    cd "$work/$stack-demo"
    git init -q -b main
    mise trust -q .config/mise/conf.d/stack.toml
    mise trust -q mise.toml
    test ! -e CLAUDE.md
    test ! -e mise.lock
    mise run setup >/dev/null
    git add -A
    mise run check
    mise run test
    if [ -n "${PROJECT_SETUP:-}" ]; then
      python3 "$PROJECT_SETUP" . --mode verify --format human
    fi
  )
done
echo "stacks render: PASS (${stacks[*]})"
