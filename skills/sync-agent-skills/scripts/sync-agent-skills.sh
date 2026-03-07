#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENT_HUB_ROOT="${AGENT_HUB_ROOT:-$(cd "$SKILL_DIR/../../../../.." && pwd)}"
HOME_DIR="${HOME:?HOME is required}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME_DIR/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME_DIR/.agents/skills}"
BOOTSTRAP_SCRIPT="$AGENT_HUB_ROOT/scripts/bootstrap.sh"
CHECK_SCRIPT="$AGENT_HUB_ROOT/scripts/check.sh"

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
  local personal_root="$AGENT_HUB_ROOT/skills/personal"
  local vendor_root="$AGENT_HUB_ROOT/skills/vendor"
  local claude_file="$1"
  local codex_file="$2"

  record_root_skill_names "$personal_root" "$claude_file"
  record_root_skill_names "$personal_root" "$codex_file"

  while read -r package_dir; do
    [[ -n "$package_dir" ]] || continue
    local package_name skill_root
    package_name="$(basename "$package_dir")"
    skill_root="$(vendor_skill_root "$package_dir")"

    if [[ "$skill_root" != "$package_dir" ]]; then
      remember "$codex_file" "$package_name"
    else
      record_root_skill_names "$skill_root" "$codex_file"
    fi

    record_root_skill_names "$skill_root" "$claude_file"
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
  local expected_claude expected_codex before_claude before_codex after_claude after_codex
  expected_claude="$(new_file)"
  expected_codex="$(new_file)"
  before_claude="$(new_file)"
  before_codex="$(new_file)"
  after_claude="$(new_file)"
  after_codex="$(new_file)"

  record_expected_names "$expected_claude" "$expected_codex"
  snapshot_names "$CLAUDE_SKILLS_DIR" "$before_claude"
  snapshot_names "$CODEX_SKILLS_DIR" "$before_codex"

  prune_unexpected "$CLAUDE_SKILLS_DIR" "$expected_claude"
  prune_unexpected "$CODEX_SKILLS_DIR" "$expected_codex"

  bash "$BOOTSTRAP_SCRIPT" --force >/dev/null
  bash "$CHECK_SCRIPT" >/dev/null

  snapshot_names "$CLAUDE_SKILLS_DIR" "$after_claude"
  snapshot_names "$CODEX_SKILLS_DIR" "$after_codex"

  print_added_removed "claude" "$before_claude" "$after_claude"
  print_added_removed "codex" "$before_codex" "$after_codex"

  rm -f "$expected_claude" "$expected_codex" "$before_claude" "$before_codex" "$after_claude" "$after_codex"
}

main "$@"
