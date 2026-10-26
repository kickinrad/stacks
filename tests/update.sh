#!/usr/bin/env bash
# copier update across a template release: owned files take the change, seeded
# files keep the project's edits, and _commit moves to the new release.
set -euo pipefail
# A pre-push hook exports its repository bindings; scratch Git commands must discover their own .git.
while IFS= read -r name; do unset "$name"; done < <(git rev-parse --local-env-vars)
template="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
copier_bin="$(cd "$template" && mise which copier)"
work="$(mktemp -d)"
export TMPDIR="$work" MISE_TRUSTED_CONFIG_PATHS="$work"
trap 'rm -rf "$work"' EXIT
mkdir "$work/template"
tar -C "$template" --exclude=./.git -cf - . | tar -C "$work/template" -xf -
cd "$work/template"
git init -q -b main
test "$(git rev-parse --path-format=absolute --git-common-dir)" != "$(git -C "$template" rev-parse --path-format=absolute --git-common-dir)"
git add -A && git -c user.email=t@t -c user.name=t commit -qm "working tree" --allow-empty
git tag v900.0.0
"$copier_bin" copy --quiet --defaults --trust --vcs-ref v900.0.0 --data stack=bun-lib "$work/template" "$work/project"
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
"$copier_bin" update --quiet --defaults --trust
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
grep -q 'could not check template releases' "$work/probe.json"
sed -i "s|^_src_path: .*|_src_path: $work/template|; /^_commit:/d" .copier-answers.yml
python3 .agents/stack/check --json > "$work/nocommit.json" || true
grep -q 'no valid _commit' "$work/nocommit.json"
# Copier's saved gh: shorthand resolves against the public template.
sed -i "s|^_src_path: .*|_src_path: gh:kickinrad/stacks|; s|^_commit: .*|_commit: v0.0.1|" .copier-answers.yml
grep -q '^_commit:' .copier-answers.yml || echo "_commit: v0.0.1" >> .copier-answers.yml
python3 .agents/stack/check --json > "$work/gh.json" || true
grep -q '"template-behind"' "$work/gh.json"
! grep -q 'could not check template releases' "$work/gh.json"
# An adopted project (samples=false) never gets starter samples back on update.
adopted="$work/adopted"
"$copier_bin" copy --quiet --defaults --trust --vcs-ref v900.0.0 --data stack=python --data samples=false "$work/template" "$adopted"
# An adopted project brings its own source.
mkdir -p "$adopted/src/adopted" && printf '"""Adopted."""\n' > "$adopted/src/adopted/__init__.py"
(cd "$adopted" && mise trust -q .config/mise/conf.d/stack.toml && mise trust -q mise.toml && mise run setup >/dev/null 2>&1 && git add -A && git -c user.email=t@t -c user.name=t commit -qm adopt)
(cd "$work/template" && printf '\n' >> _shared/base/STACK.md.partial && git -c user.email=t@t -c user.name=t commit -qam bump && git tag v900.0.2)
(cd "$adopted" && "$copier_bin" update --quiet --defaults --trust --skip-tasks)
test ! -e "$adopted/tests"
test "$(cat "$adopted/src/adopted/__init__.py")" = '"""Adopted."""'
echo "stacks update: PASS"
