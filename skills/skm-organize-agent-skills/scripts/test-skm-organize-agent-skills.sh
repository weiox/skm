#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORGANIZE_SCRIPT="$SCRIPT_DIR/skm-organize-agent-skills.sh"

FAKE_HOME="$(mktemp -d)"
trap 'rm -rf "$FAKE_HOME"' EXIT
FAKE_HOME_REAL="$(cd "$FAKE_HOME" && pwd -P)"

mkdir -p "$FAKE_HOME/.skm" "$FAKE_HOME/.agents/skills" "$FAKE_HOME/.claude/skills"

mkdir -p "$FAKE_HOME/ad-hoc/local-helper"
cat >"$FAKE_HOME/ad-hoc/local-helper/SKILL.md" <<'EOF'
---
name: local-helper
description: Use when testing organize inventory
---
EOF

mkdir -p "$FAKE_HOME/.codex/skills/.system/system-helper"
cat >"$FAKE_HOME/.codex/skills/.system/system-helper/SKILL.md" <<'EOF'
---
name: system-helper
description: Use when testing ignored system skills
---
EOF

mkdir -p "$FAKE_HOME/external/sample-pack/skills/upstream-helper"
cat >"$FAKE_HOME/external/sample-pack/skills/upstream-helper/SKILL.md" <<'EOF'
---
name: upstream-helper
description: Use when testing vendor inventory
---
EOF
git -C "$FAKE_HOME/external/sample-pack" init -q >/dev/null
git -C "$FAKE_HOME/external/sample-pack" add . >/dev/null
git -C "$FAKE_HOME/external/sample-pack" -c user.name='Test User' -c user.email='test@example.com' commit -qm "init" >/dev/null

output="$(
  HOME="$FAKE_HOME" \
  SKM_DIR="$FAKE_HOME/.skm" \
  bash "$ORGANIZE_SCRIPT" \
    --scan-root "$FAKE_HOME/ad-hoc" \
    --scan-root "$FAKE_HOME/external/sample-pack"
)"

printf '%s\n' "$output"

grep -Fq "MODE dry-run" <<<"$output" || {
  echo "FAIL: expected dry-run mode banner" >&2
  exit 1
}

grep -Fq "PLAN personal local-helper" <<<"$output" || {
  echo "FAIL: expected personal classification for ad-hoc skill" >&2
  exit 1
}

grep -Fq "target=$FAKE_HOME_REAL/.skm/personal/local-helper" <<<"$output" || {
  echo "FAIL: expected personal target under ~/.skm/personal" >&2
  exit 1
}

grep -Fq "PLAN vendor upstream-helper" <<<"$output" || {
  echo "FAIL: expected vendor classification for git-backed skill pack" >&2
  exit 1
}

grep -Fq "target=$FAKE_HOME_REAL/.skm/vendor/sample-pack" <<<"$output" || {
  echo "FAIL: expected vendor target under ~/.skm/vendor" >&2
  exit 1
}

grep -Fq "PLAN ignore system-helper" <<<"$output" || {
  echo "FAIL: expected ignore classification for .codex/.system skill" >&2
  exit 1
}

apply_output="$(
  HOME="$FAKE_HOME" \
  SKM_DIR="$FAKE_HOME/.skm" \
  bash "$ORGANIZE_SCRIPT" \
    --apply \
    --scan-root "$FAKE_HOME/ad-hoc" \
    --scan-root "$FAKE_HOME/external/sample-pack"
)"

printf '%s\n' "$apply_output"

grep -Fq "MODE apply" <<<"$apply_output" || {
  echo "FAIL: expected apply mode banner" >&2
  exit 1
}

grep -Fq "APPLY personal local-helper" <<<"$apply_output" || {
  echo "FAIL: expected personal apply action" >&2
  exit 1
}

grep -Fq "APPLY vendor sample-pack" <<<"$apply_output" || {
  echo "FAIL: expected vendor apply action" >&2
  exit 1
}

[[ -d "$FAKE_HOME_REAL/.skm/personal/local-helper" ]] || {
  echo "FAIL: expected local helper to move under ~/.skm/personal" >&2
  exit 1
}

[[ -d "$FAKE_HOME_REAL/.skm/vendor/sample-pack" ]] || {
  echo "FAIL: expected vendor pack to move under ~/.skm/vendor" >&2
  exit 1
}

[[ "$(readlink "$FAKE_HOME/.agents/skills")" == "$FAKE_HOME_REAL/.skm/exports/shared" ]] || {
  echo "FAIL: expected Codex entrypoint to point at exports/shared" >&2
  exit 1
}

[[ "$(readlink "$FAKE_HOME/.claude/skills")" == "$FAKE_HOME_REAL/.skm/exports/shared" ]] || {
  echo "FAIL: expected Claude entrypoint to point at exports/shared" >&2
  exit 1
}

[[ "$(readlink "$FAKE_HOME_REAL/.skm/exports/shared/local-helper")" == "$FAKE_HOME_REAL/.skm/personal/local-helper" ]] || {
  echo "FAIL: expected local helper export link to exist" >&2
  exit 1
}

[[ "$(readlink "$FAKE_HOME_REAL/.skm/exports/shared/upstream-helper")" == "$FAKE_HOME_REAL/.skm/vendor/sample-pack/skills/upstream-helper" ]] || {
  echo "FAIL: expected vendor helper export link to exist" >&2
  exit 1
}

echo "PASS: organize script inventories and applies personal and vendor candidates"
