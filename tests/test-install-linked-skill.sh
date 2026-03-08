#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/test-lib.sh
source "$SCRIPT_DIR/test-lib.sh"

FAKE_HOME="$(make_fake_home)"
trap 'rm -rf "$FAKE_HOME"' EXIT

FAKE_SKM="$FAKE_HOME/.skm"
SOURCE_REPO="$FAKE_HOME/source-pack"
FIXTURE_ROOT="$SCRIPT_DIR/fixtures/vendor-pack-basic"

mkdir -p "$FAKE_SKM"
link_repo_scripts_into_fake_skm "$FAKE_SKM"
git -C "$FAKE_SKM" init -q >/dev/null
FAKE_SKM_REAL="$(canonical_dir "$FAKE_SKM")"

mkdir -p "$SOURCE_REPO"
cp -R "$FIXTURE_ROOT"/. "$SOURCE_REPO"/
init_git_repo "$SOURCE_REPO"

install_output="$(
  run_in_fake_home "$FAKE_HOME" \
    env SKM_DIR="$FAKE_SKM" \
    bash "$INSTALL_SCRIPT" "$SOURCE_REPO"
)"

printf '%s\n' "$install_output"

assert_output_contains "$install_output" "STATUS: installed"
assert_output_contains "$install_output" "PACKAGE: source-pack"
assert_output_contains "$install_output" "TARGET: $FAKE_SKM_REAL/vendor/source-pack"

assert_path_exists "$FAKE_SKM_REAL/vendor/source-pack/.git"
assert_symlink_target "$FAKE_HOME/.agents/skills" "$FAKE_SKM_REAL/exports/shared"
assert_symlink_target "$FAKE_HOME/.claude/skills" "$FAKE_SKM_REAL/exports/shared"
assert_symlink_target "$FAKE_SKM_REAL/exports/shared/example-skill" "$FAKE_SKM_REAL/vendor/source-pack/skills/example-skill"

check_output="$(
  run_in_fake_home "$FAKE_HOME" \
    env SKM_DIR="$FAKE_SKM" \
    bash "$CHECK_SCRIPT"
)"

assert_output_contains "$check_output" "PASS: skm links verified"

echo "PASS: install-linked-skill imports a local git repo into vendor and rebuilds entrypoints"
