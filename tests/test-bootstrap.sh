#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/test-lib.sh
source "$SCRIPT_DIR/test-lib.sh"

FAKE_HOME="$(make_fake_home)"
trap 'rm -rf "$FAKE_HOME"' EXIT

FAKE_SKM="$FAKE_HOME/.skm"
link_repo_scripts_into_fake_skm "$FAKE_SKM"
mkdir -p "$FAKE_SKM/personal" "$FAKE_SKM/vendor/basic-pack/skills"

write_skill "$FAKE_SKM/personal" "local-skill" "Use when testing bootstrap personal export"
write_skill "$FAKE_SKM/vendor/basic-pack/skills" "vendor-skill" "Use when testing bootstrap vendor export"

run_in_fake_home "$FAKE_HOME" env SKM_DIR="$FAKE_SKM" bash "$BOOTSTRAP_SCRIPT" --force >/tmp/skm-test-bootstrap.out
run_in_fake_home "$FAKE_HOME" env SKM_DIR="$FAKE_SKM" bash "$CHECK_SCRIPT" >/tmp/skm-test-bootstrap-check.out

FAKE_SKM_REAL="$(canonical_dir "$FAKE_SKM")"

assert_symlink_target "$FAKE_HOME/.agents/skills" "$FAKE_SKM_REAL/exports/shared"
assert_symlink_target "$FAKE_HOME/.claude/skills" "$FAKE_SKM_REAL/exports/shared"
assert_symlink_target "$FAKE_SKM_REAL/exports/shared/local-skill" "$FAKE_SKM_REAL/personal/local-skill"
assert_symlink_target "$FAKE_SKM_REAL/exports/shared/vendor-skill" "$FAKE_SKM_REAL/vendor/basic-pack/skills/vendor-skill"

assert_output_contains "$(cat /tmp/skm-test-bootstrap-check.out)" "PASS: skm links verified"

echo "PASS: bootstrap exports personal and vendor skills into shared entrypoints"
