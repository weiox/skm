#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOME_DIR="${HOME:?HOME is required}"
SKM_DIR="${SKM_DIR:-$(cd "$SKILL_DIR/../.." && pwd)}"
SKM_EXPORTS_DIR="${SKM_EXPORTS_DIR:-$SKM_DIR/exports}"
SKM_SHARED_EXPORT_DIR="${SKM_SHARED_EXPORT_DIR:-$SKM_EXPORTS_DIR/shared}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME_DIR/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME_DIR/.agents/skills}"
BOOTSTRAP_SCRIPT="$SKM_DIR/scripts/bootstrap.sh"
CHECK_SCRIPT="$SKM_DIR/scripts/check.sh"

new_file() {
  mktemp
}

remember() {
  local file="$1"
  local value="$2"
  grep -Fxq -- "$value" "$file" 2>/dev/null || printf '%s\n' "$value" >> "$file"
}

iter_skill_dirs() {
  local source_root="$1"
  [[ -d "$source_root" ]] || return 0
  find "$source_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r skill_dir; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    printf '%s\n' "$skill_dir"
  done
}

iter_vendor_packages() {
  local vendor_root="$1"
  [[ -d "$vendor_root" ]] || return 0
  find "$vendor_root" -mindepth 1 -maxdepth 1 -type d | sort
}

vendor_skill_root() {
  local package_dir="$1"
  if [[ -d "$package_dir/skills" ]]; then
    printf '%s\n' "$package_dir/skills"
  else
    printf '%s\n' "$package_dir"
  fi
}

record_root_skill_names() {
  local source_root="$1"
  local out_file="$2"

  while read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    remember "$out_file" "$(basename "$skill_dir")"
  done < <(iter_skill_dirs "$source_root")
}

record_expected_names() {
  local personal_root="$SKM_DIR/personal"
  local vendor_root="$SKM_DIR/vendor"
  local shared_file="$1"

  record_root_skill_names "$SKM_DIR/skills" "$shared_file"
  record_root_skill_names "$personal_root" "$shared_file"

  while read -r package_dir; do
    [[ -n "$package_dir" ]] || continue
    local skill_root
    skill_root="$(vendor_skill_root "$package_dir")"
    record_root_skill_names "$skill_root" "$shared_file"
  done < <(iter_vendor_packages "$vendor_root")
}

snapshot_names() {
  local target_dir="$1"
  local out_file="$2"
  [[ -d "$target_dir" ]] || return 0
  find "$target_dir" -mindepth 1 -maxdepth 1 -type l | sort | while read -r path; do
    remember "$out_file" "$(basename "$path")"
  done
}

prune_unexpected() {
  local target_dir="$1"
  local expected_file="$2"
  [[ -d "$target_dir" ]] || return 0

  find "$target_dir" -mindepth 1 -maxdepth 1 -type l | sort | while read -r path; do
    local name
    name="$(basename "$path")"
    if ! grep -Fxq -- "$name" "$expected_file" 2>/dev/null; then
      rm -f "$path"
    fi
  done
}

print_added_removed() {
  local label="$1"
  local before_file="$2"
  local after_file="$3"

  while read -r name; do
    [[ -n "$name" ]] || continue
    if ! grep -Fxq -- "$name" "$before_file" 2>/dev/null; then
      printf 'ADDED %s %s\n' "$label" "$name"
    fi
  done < <(sort -u "$after_file")

  while read -r name; do
    [[ -n "$name" ]] || continue
    if ! grep -Fxq -- "$name" "$after_file" 2>/dev/null; then
      printf 'REMOVED %s %s\n' "$label" "$name"
    fi
  done < <(sort -u "$before_file")
}

main() {
  local expected_shared before_shared after_shared
  expected_shared="$(new_file)"
  before_shared="$(new_file)"
  after_shared="$(new_file)"

  record_expected_names "$expected_shared"
  snapshot_names "$CODEX_SKILLS_DIR" "$before_shared"
  snapshot_names "$CLAUDE_SKILLS_DIR" "$before_shared"
  snapshot_names "$SKM_SHARED_EXPORT_DIR" "$before_shared"

  bash "$BOOTSTRAP_SCRIPT" --force >/dev/null
  bash "$CHECK_SCRIPT" >/dev/null

  snapshot_names "$SKM_SHARED_EXPORT_DIR" "$after_shared"

  print_added_removed "shared" "$before_shared" "$after_shared"

  rm -f "$expected_shared" "$before_shared" "$after_shared"
}

main "$@"
