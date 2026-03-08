#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKM_DIR="${SKM_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SHARED_EXPORT_DIR="${SKM_SHARED_EXPORT_DIR:-$SKM_DIR/exports/shared}"
HOME_DIR="${HOME:?HOME is required}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME_DIR/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME_DIR/.agents/skills}"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_symlink_to() {
  local path="$1" expected="$2"
  [[ -L "$path" ]] || fail "expected symlink: $path"
  local actual
  actual="$(readlink "$path")"
  [[ "$actual" == "$expected" ]] || fail "expected $path -> $expected, got $actual"
}
assert_skill_source_exists() {
  local dir="$1"
  [[ -d "$dir" ]] || fail "missing source dir: $dir"
  [[ -f "$dir/SKILL.md" ]] || fail "missing SKILL.md: $dir/SKILL.md"
}

sources_file="$(mktemp)"
trap 'rm -f "$sources_file"' EXIT

remember_skill_source() {
  local entry_name="$1"
  local source_dir="$2"
  printf '%s\t%s\n' "$entry_name" "$source_dir" >> "$sources_file"
}

print_conflicts() {
  awk -F '\t' '
    {
      key = $1 FS $2
      if (seen[key]++) next
      count[$1]++
      sources[$1] = sources[$1] ? sources[$1] " ; " $2 : $2
    }
    END {
      for (name in count) {
        if (count[name] > 1) {
          printf "%s\t%s\n", name, sources[name]
        }
      }
    }
  ' "$sources_file" | sort | while IFS=$'\t' read -r name sources; do
    [[ -n "$name" ]] || continue
    printf 'CONFLICT %s -> %s\n' "$name" "$sources"
  done
}

assert_no_conflicts() {
  local conflict_output
  conflict_output="$(print_conflicts)"
  [[ -z "$conflict_output" ]] || fail "$conflict_output"
}
iter_skill_dirs() {
  local source_root="$1"
  [[ -d "$source_root" ]] || return 0
  find "$source_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r skill_dir; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    printf '%s\n' "$skill_dir"
  done
}
vendor_skill_root() {
  local package_dir="$1"
  if [[ -d "$package_dir/skills" ]]; then
    printf '%s\n' "$package_dir/skills"
  else
    printf '%s\n' "$package_dir"
  fi
}
record_root_skill_sources() {
  local source_root="$1"
  while read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    assert_skill_source_exists "$skill_dir"
    remember_skill_source "$(basename "$skill_dir")" "$skill_dir"
  done < <(iter_skill_dirs "$source_root")
}

check_root_skill_dirs() {
  local source_root="$1"
  while read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    assert_skill_source_exists "$skill_dir"
    assert_symlink_to "$SHARED_EXPORT_DIR/$(basename "$skill_dir")" "$skill_dir"
  done < <(iter_skill_dirs "$source_root")
}
record_vendor_skill_sources() {
  local vendor_root="$1"
  [[ -d "$vendor_root" ]] || return 0
  find "$vendor_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r package_dir; do
    record_root_skill_sources "$(vendor_skill_root "$package_dir")"
  done
}

check_vendor_packages() {
  local vendor_root="$1"
  [[ -d "$vendor_root" ]] || return 0
  find "$vendor_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r package_dir; do
    check_root_skill_dirs "$(vendor_skill_root "$package_dir")"
  done
}
assert_symlink_to "$CLAUDE_SKILLS_DIR" "$SHARED_EXPORT_DIR"
assert_symlink_to "$CODEX_SKILLS_DIR" "$SHARED_EXPORT_DIR"
record_root_skill_sources "$SKM_DIR/skills"
record_root_skill_sources "$SKM_DIR/personal"
record_vendor_skill_sources "$SKM_DIR/vendor"
assert_no_conflicts
check_root_skill_dirs "$SKM_DIR/skills"
check_root_skill_dirs "$SKM_DIR/personal"
check_vendor_packages "$SKM_DIR/vendor"
printf 'PASS: skm links verified\n'
