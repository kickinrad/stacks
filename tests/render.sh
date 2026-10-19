#!/usr/bin/env bash
# Render each stack (or the ones named) into a scratch repo and run its own gates.
# PROJECT_SETUP may point at project-setup's project_setup.py to add its verify.
set -euo pipefail
template="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stacks=("$@")
[ ${#stacks[@]} -gt 0 ] || mapfile -t stacks < <(cd "$template" && for d in */; do [ -e "$d{{ _copier_conf.answers_file }}.jinja" ] && echo "${d%/}"; done)
work="$(mktemp -d)"
[ -n "${KEEP:-}" ] && echo "work: $work" || trap 'rm -rf "$work"' EXIT
for stack in "${stacks[@]}"; do
  echo "== $stack"
  creator="$(python3 -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb")).get(sys.argv[2], {}).get("run", ""))' "$template/creators.toml" "$stack")"
  if [ -n "$creator" ]; then
    (cd "$work" && sh -c "${creator//\{dir\}/$stack-demo}" >/dev/null)
  fi
  copier copy --quiet --defaults --trust --overwrite --vcs-ref HEAD \
    --data stack="$stack" --data description="Render test" "$template" "$work/$stack-demo"
  (
    cd "$work/$stack-demo"
    git rev-parse --git-dir >/dev/null 2>&1 || git init -q -b main
    mise trust -q .config/mise/conf.d/stack.toml
    mise trust -q mise.toml
    export CI=1
    test ! -e CLAUDE.md
    test ! -e mise.lock
    mise run setup >/dev/null
    git add -A
    mise run check
    mise run test
    if mise tasks --json | grep -q '"name": "e2e"'; then mise run e2e; fi
    python3 .agents/stack/check --structure
    test -x .agents/stack/check
    if [ -n "${PROJECT_SETUP:-}" ]; then
      python3 "$PROJECT_SETUP" . --mode verify --format human
    fi
  )
done
echo "stacks render: PASS (${stacks[*]})"
