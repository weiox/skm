#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKM_REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
BOOTSTRAP_SCRIPT="$SKM_REPO_ROOT/scripts/bootstrap.sh"
CHECK_SCRIPT="$SKM_REPO_ROOT/scripts/check.sh"
SYNC_SCRIPT="$SKM_REPO_ROOT/skills/skm-sync-agent-skills/scripts/skm-sync-agent-skills.sh"
INSTALL_SCRIPT="$SKM_REPO_ROOT/skills/skm-install-linked-agent-skills/scripts/skm-install-linked-skill.sh"
UPDATE_SCRIPT="$SKM_REPO_ROOT/skills/skm-update-vendor-skills/scripts/skm-update-vendor-skills.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

make_fake_home() {
  local dir
  dir="$(mktemp -d)"
  canonical_dir "$dir"
}

canonical_dir() {
  local path="$1"
  (
    cd "$path"
    pwd -P
  )
}

canonicalize_path_if_present() {
  local path="$1"
  if [[ -d "$path" || -L "$path" ]]; then
    canonical_dir "$path"
    return 0
  fi
  printf '%s\n' "$path"
}

write_skill() {
  local parent_dir="$1"
  local skill_name="$2"
  local description="${3:-Use when running fake-home tests}"

  mkdir -p "$parent_dir/$skill_name"
  cat >"$parent_dir/$skill_name/SKILL.md" <<EOF
---
name: $skill_name
description: $description
---
EOF
}

init_git_repo() {
  local repo_dir="$1"
  git -C "$repo_dir" init -q >/dev/null
  git -C "$repo_dir" add . >/dev/null
  git -C "$repo_dir" -c user.name='Test User' -c user.email='test@example.com' commit -qm "init" >/dev/null
}

link_repo_scripts_into_fake_skm() {
  local fake_skm="$1"
  mkdir -p "$fake_skm"
  ln -s "$SKM_REPO_ROOT/scripts" "$fake_skm/scripts"
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  [[ -L "$path" ]] || fail "expected symlink: $path"
  local actual
  actual="$(readlink "$path")"
  actual="$(canonicalize_path_if_present "$actual")"
  expected="$(canonicalize_path_if_present "$expected")"
  [[ "$actual" == "$expected" ]] || fail "expected $path -> $expected, got $actual"
}

assert_path_exists() {
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || fail "expected path to exist: $path"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" && ! -L "$path" ]] || fail "expected path to be absent: $path"
}

assert_output_contains() {
  local output="$1"
  local expected="$2"
  grep -Fq -- "$expected" <<<"$output" || fail "expected output to contain: $expected"
}

run_in_fake_home() {
  local fake_home="$1"
  shift
  HOME="$fake_home" "$@"
}
