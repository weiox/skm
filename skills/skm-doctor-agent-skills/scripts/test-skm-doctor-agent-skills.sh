#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCTOR_SCRIPT="$SCRIPT_DIR/skm-doctor-agent-skills.sh"
SKM_DIR_REAL="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BOOTSTRAP_SCRIPT="$SKM_DIR_REAL/scripts/bootstrap.sh"
CHECK_SCRIPT="$SKM_DIR_REAL/scripts/check.sh"

FAKE_HOME="$(mktemp -d)"
trap 'rm -rf "$FAKE_HOME"' EXIT

mkdir -p "$FAKE_HOME/.skm/personal/example-skill"
cat >"$FAKE_HOME/.skm/personal/example-skill/SKILL.md" <<'EOF'
---
name: example-skill
description: Use when testing doctor entrypoints
---
EOF
mkdir -p "$FAKE_HOME/.skm/vendor/sample-pack/skills/example-skill"
cat >"$FAKE_HOME/.skm/vendor/sample-pack/skills/example-skill/SKILL.md" <<'EOF'
---
name: example-skill
description: Use when testing doctor conflicts
---
EOF
mkdir -p "$FAKE_HOME/.skm/exports/shared"
ln -s "$FAKE_HOME/.skm/personal/example-skill" "$FAKE_HOME/.skm/exports/shared/example-skill"
mkdir -p "$FAKE_HOME/.claude" "$FAKE_HOME/.agents"
ln -s "$FAKE_HOME/.skm/exports/shared" "$FAKE_HOME/.claude/skills"
ln -s "$FAKE_HOME/.skm/exports/shared" "$FAKE_HOME/.agents/skills"

output="$(HOME="$FAKE_HOME" SKM_DIR="$FAKE_HOME/.skm" bash "$DOCTOR_SCRIPT")"

printf '%s\n' "$output"

grep -Fq "OK codex example-skill" <<<"$output" || {
  echo "FAIL: expected codex entrypoint to be reported" >&2
  exit 1
}

grep -Fq "OK claude example-skill" <<<"$output" || {
  echo "FAIL: expected claude entrypoint to be reported" >&2
  exit 1
}

grep -Fq "CONFLICT example-skill" <<<"$output" || {
  echo "FAIL: expected conflict to be reported" >&2
  exit 1
}

if HOME="$FAKE_HOME" SKM_DIR="$FAKE_HOME/.skm" bash "$BOOTSTRAP_SCRIPT" --force >/tmp/skm-bootstrap-conflict.out 2>&1; then
  echo "FAIL: expected bootstrap to fail on duplicate skill names" >&2
  cat /tmp/skm-bootstrap-conflict.out >&2
  exit 1
fi

grep -Fq "CONFLICT example-skill" /tmp/skm-bootstrap-conflict.out || {
  echo "FAIL: expected bootstrap conflict message" >&2
  cat /tmp/skm-bootstrap-conflict.out >&2
  exit 1
}

if HOME="$FAKE_HOME" SKM_DIR="$FAKE_HOME/.skm" bash "$CHECK_SCRIPT" >/tmp/skm-check-conflict.out 2>&1; then
  echo "FAIL: expected check.sh to fail on duplicate skill names" >&2
  cat /tmp/skm-check-conflict.out >&2
  exit 1
fi

grep -Fq "CONFLICT example-skill" /tmp/skm-check-conflict.out || {
  echo "FAIL: expected check.sh conflict message" >&2
  cat /tmp/skm-check-conflict.out >&2
  exit 1
}

echo "PASS: doctor script reports conflicts and bootstrap/check reject duplicate skill names"
