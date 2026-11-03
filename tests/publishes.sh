#!/usr/bin/env bash
# A library stack adds release-please only when it publishes, starting at 0.x.
set -euo pipefail
git_local_env="$(git rev-parse --local-env-vars)"
while IFS= read -r name; do [ -z "$name" ] || unset "$name"; done <<< "$git_local_env"
template="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
files=(release-please-config.json .release-please-manifest.json .github/workflows/release.yml)
for stack in bun-lib python; do
  for publishes in true false; do
    dir="$work/$stack-$publishes"
    copier copy --quiet --defaults --trust --overwrite --vcs-ref HEAD --skip-tasks \
      --data stack="$stack" --data publishes="$publishes" --data samples=false "$template" "$dir"
    for f in "${files[@]}"; do
      if [ "$publishes" = true ]; then test -s "$dir/$f"; else test ! -e "$dir/$f"; fi
    done
    if [ "$publishes" = true ]; then
      python3 -c 'import json, sys; c = json.load(open(sys.argv[1])); assert c["bump-minor-pre-major"] is True; assert json.load(open(sys.argv[2])) == {".": "0.1.0"}' \
        "$dir/release-please-config.json" "$dir/.release-please-manifest.json"
    fi
  done
done
echo "stacks publishes: PASS"
