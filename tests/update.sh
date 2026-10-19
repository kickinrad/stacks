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
if python3 .agents/stack/check --json > "$work/before.json"; then echo "check passed while a release behind" >&2; exit 1; fi
grep -q '"template-behind"' "$work/before.json"
grep -q '"latest": "v900.0.1"' "$work/before.json"
copier update --quiet --defaults --trust
grep -q "Release marker: v900.0.1" .agents/stack/STACK.md
grep -q "Project note." AGENTS.md
! grep -q "must not reach" AGENTS.md
grep -q "_commit: v900.0.1" .copier-answers.yml
python3 .agents/stack/check --json > "$work/after.json" || true
! grep -q '"template-behind"' "$work/after.json"
# A removed base facet is structural drift; an unreadable probe is "unknown", never clean.
sed -i '/STACK.md/d' AGENTS.md
if python3 .agents/stack/check --structure > "$work/facet.txt"; then echo "check passed without the STACK.md link" >&2; exit 1; fi
grep -q "missing-facet: AGENTS.md does not link" "$work/facet.txt"
sed -i "s|^_src_path: .*|_src_path: $work/no-such-template|" .copier-answers.yml
python3 .agents/stack/check --json > "$work/probe.json" || true
grep -q '"probe-failed"' "$work/probe.json"
echo "stacks update: PASS"
