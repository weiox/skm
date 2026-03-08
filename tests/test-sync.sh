#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/test-lib.sh
source "$SCRIPT_DIR/test-lib.sh"

FAKE_HOME="$(make_fake_home)"
trap 'rm -rf "$FAKE_HOME"' EXIT

FAKE_SKM="$FAKE_HOME/.skm"
FAKE_SKM_REAL="$FAKE_SKM"
mkdir -p "$FAKE_SKM/personal" "$FAKE_SKM/exports/shared" "$FAKE_SKM/scripts" "$FAKE_HOME/outside"

ln -s "$BOOTSTRAP_SCRIPT" "$FAKE_SKM/scripts/bootstrap.sh"
ln -s "$CHECK_SCRIPT" "$FAKE_SKM/scripts/check.sh"

write_skill "$FAKE_SKM/personal" "live-skill" "Use when testing sync regeneration"

ln -s "$FAKE_HOME/outside/missing-stale" "$FAKE_SKM/exports/shared/stale-skill"

mkdir -p "$FAKE_HOME/.agents/skills" "$FAKE_HOME/.claude/skills"
ln -s "$FAKE_HOME/outside/unmanaged-codex" "$FAKE_HOME/.agents/skills/unmanaged-skill"
ln -s "$FAKE_HOME/outside/unmanaged-claude" "$FAKE_HOME/.claude/skills/unmanaged-skill"

sync_output="$(run_in_fake_home "$FAKE_HOME" env SKM_DIR="$FAKE_SKM" bash "$SYNC_SCRIPT")"
printf '%s\n' "$sync_output"

FAKE_SKM_REAL="$(canonical_dir "$FAKE_SKM")"

assert_output_contains "$sync_output" "ADDED shared live-skill"
assert_output_contains "$sync_output" "REMOVED shared stale-skill"
assert_output_contains "$sync_output" "NOTE session restart"

assert_symlink_target "$FAKE_HOME/.agents/skills" "$FAKE_SKM_REAL/exports/shared"
assert_symlink_target "$FAKE_HOME/.claude/skills" "$FAKE_SKM_REAL/exports/shared"
assert_symlink_target "$FAKE_SKM_REAL/exports/shared/live-skill" "$FAKE_SKM_REAL/personal/live-skill"
assert_not_exists "$FAKE_SKM_REAL/exports/shared/stale-skill"

echo "PASS: sync prunes stale shared links and restores shared entrypoints"
