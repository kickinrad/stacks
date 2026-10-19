#!/usr/bin/env bash
# copier update across a template release: owned files take the change, seeded
# files keep the project's edits, and _commit moves to the new release.
set -euo pipefail
template="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -r "$template" "$work/template"
cd "$work/template"
git add -A && git -c user.email=t@t -c user.name=t commit -qm "working tree" --allow-empty
git tag v900.0.0
copier copy --quiet --defaults --trust --vcs-ref v900.0.0 --data stack=bun-lib "$work/template" "$work/project"
cd "$work/project"
mise trust -q .config/mise/conf.d/stack.toml
mise trust -q mise.toml
mise run setup >/dev/null
git add -A && git -c user.email=t@t -c user.name=t commit -qm adopt
echo "Project note." >> AGENTS.md
git -c user.email=t@t -c user.name=t commit -qam "project edit"
cd "$work/template"
printf '\n- Release marker: v900.0.1.\n' >> _shared/base/STACK.md.partial
printf '\nSeed change that must not reach existing projects.\n' >> _shared/base/AGENTS.md.partial
git -c user.email=t@t -c user.name=t commit -qam "owned and seeded change"
git tag v900.0.1
cd "$work/project"
copier update --quiet --defaults --trust
grep -q "Release marker: v900.0.1" .agents/stack/STACK.md
grep -q "Project note." AGENTS.md
! grep -q "must not reach" AGENTS.md
grep -q "_commit: v900.0.1" .copier-answers.yml
echo "stacks update: PASS"
