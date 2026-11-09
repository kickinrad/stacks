#!/usr/bin/env bash
# The expo stack's Storybook facet renders only when chosen, and the checker reports Storybook packages split across majors.
set -euo pipefail
git_local_env="$(git rev-parse --local-env-vars)"
while IFS= read -r name; do [ -z "$name" ] || unset "$name"; done <<< "$git_local_env"
template="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
facet=(.rnstorybook/main.ts .storybook/main.ts metro.config.js .mcp.json src/components/greeting.stories.tsx)
for storybook in true false; do
  dir="$work/expo-$storybook"
  copier copy --quiet --defaults --trust --overwrite --vcs-ref HEAD --skip-tasks \
    --data stack=expo --data storybook="$storybook" "$template" "$dir"
  for f in "${facet[@]}"; do
    if [ "$storybook" = true ]; then test -s "$dir/$f"; else test ! -e "$dir/$f"; fi
  done
  if [ "$storybook" = true ]; then
    grep -q "storybook-device" "$dir/.config/mise/conf.d/stack.toml"
    grep -q "mcp_servers.storybook" "$dir/.codex/config.toml"
  else
    ! grep -q "storybook" "$dir/.config/mise/conf.d/stack.toml" "$dir/.codex/config.toml" "$dir/.agents/stack/STACK.md"
  fi
done
dir="$work/expo-true"
printf '{"devDependencies": {"storybook": "^10.6.6", "@storybook/react-native": "^11.0.0"}}\n' > "$dir/package.json"
printf '{\n  "packages": {\n    "storybook": ["storybook@10.6.6", ""],\n    "@storybook/react-native": ["@storybook/react-native@11.0.0", ""],\n    "@storybook/global": ["@storybook/global@5.0.0", ""],\n  }\n}\n' > "$dir/bun.lock"
if python3 "$dir/.agents/stack/check" --structure > "$work/split.txt"; then echo "check passed with Storybook on two majors" >&2; exit 1; fi
grep -q "storybook-major: Storybook packages span majors \['10', '11'\]" "$work/split.txt"
sed -i 's/@11.0.0/@10.7.1/' "$dir/bun.lock"
python3 "$dir/.agents/stack/check" --structure > "$work/aligned.txt" || true
! grep -q "storybook-major" "$work/aligned.txt"
echo "stacks expo facets: PASS"
