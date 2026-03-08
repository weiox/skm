#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/test-lib.sh
source "$SCRIPT_DIR/test-lib.sh"

FAKE_HOME="$(make_fake_home)"
trap 'rm -rf "$FAKE_HOME"' EXIT

FAKE_SKM="$FAKE_HOME/.skm"
SOURCE_REPO="$FAKE_HOME/source-pack"
BASIC_FIXTURE="$SCRIPT_DIR/fixtures/vendor-pack-basic"
UPDATED_FIXTURE="$SCRIPT_DIR/fixtures/vendor-pack-updated"

mkdir -p "$FAKE_SKM"
link_repo_scripts_into_fake_skm "$FAKE_SKM"
git -C "$FAKE_SKM" init -q >/dev/null
FAKE_SKM_REAL="$(canonical_dir "$FAKE_SKM")"

mkdir -p "$SOURCE_REPO"
cp -R "$BASIC_FIXTURE"/. "$SOURCE_REPO"/
init_git_repo "$SOURCE_REPO"

git -C "$FAKE_SKM" -c protocol.file.allow=always submodule add --quiet "$SOURCE_REPO" "vendor/source-pack" >/dev/null
git -C "$FAKE_SKM" -c protocol.file.allow=always submodule update --init --recursive --quiet "vendor/source-pack" >/dev/null

run_in_fake_home "$FAKE_HOME" env SKM_DIR="$FAKE_SKM" bash "$BOOTSTRAP_SCRIPT" --force >/dev/null

before_revision="$(git -C "$FAKE_SKM/vendor/source-pack" rev-parse HEAD)"

cp -R "$UPDATED_FIXTURE"/. "$SOURCE_REPO"/
git -C "$SOURCE_REPO" add . >/dev/null
git -C "$SOURCE_REPO" -c user.name='Test User' -c user.email='test@example.com' commit -qm "update fixture" >/dev/null

source_revision="$(git -C "$SOURCE_REPO" rev-parse HEAD)"

update_output="$(
  run_in_fake_home "$FAKE_HOME" \
    env SKM_DIR="$FAKE_SKM" \
    bash "$UPDATE_SCRIPT" source-pack
)"

printf '%s\n' "$update_output"

after_revision="$(git -C "$FAKE_SKM/vendor/source-pack" rev-parse HEAD)"

[[ "$before_revision" != "$after_revision" ]] || fail "expected vendor revision to change after update"
[[ "$after_revision" == "$source_revision" ]] || fail "expected vendor revision to match updated source repo"

assert_output_contains "$update_output" "UPDATED source-pack"
assert_symlink_target "$FAKE_SKM_REAL/exports/shared/example-skill" "$FAKE_SKM_REAL/vendor/source-pack/skills/example-skill"
assert_output_contains "$(cat "$FAKE_SKM_REAL/vendor/source-pack/skills/example-skill/SKILL.md")" "updated vendor fixture content"

echo "PASS: update-vendor-skills advances a local submodule-backed vendor package"
