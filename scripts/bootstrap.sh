#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKM_DIR="${SKM_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SHARED_EXPORT_DIR="${SKM_SHARED_EXPORT_DIR:-$SKM_DIR/exports/shared}"
HOME_DIR="${HOME:?HOME is required}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME_DIR/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME_DIR/.agents/skills}"
FORCE=0

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [--force]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

ensure_dir() { mkdir -p "$1"; }

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

link_named_target() {
  local entry_name="$1"
  local source_dir="$2"
  local target_dir="$3"
  local target_path="$target_dir/$entry_name"
  ensure_dir "$target_dir"
  if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$source_dir" ]]; then
    printf 'OK   %s\n' "$target_path"
    return 0
  fi
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
      printf 'WARN: skip existing path: %s\n' "$target_path" >&2
      return 0
    fi
    rm -rf "$target_path"
  fi
  ln -s "$source_dir" "$target_path"
  printf 'LINK %s -> %s\n' "$target_path" "$source_dir"
}

expected_file="$(mktemp)"
trap 'rm -f "$expected_file"' EXIT
remember_expected() {
  local entry_name="$1"
  grep -Fxq -- "$entry_name" "$expected_file" 2>/dev/null || printf '%s\n' "$entry_name" >> "$expected_file"
}

record_root_skill_names() {
  local source_root="$1"
  while read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    remember_expected "$(basename "$skill_dir")"
  done < <(iter_skill_dirs "$source_root")
}

link_root_skill_dirs() {
  local source_root="$1"
  while read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    link_named_target "$(basename "$skill_dir")" "$skill_dir" "$SHARED_EXPORT_DIR"
  done < <(iter_skill_dirs "$source_root")
}

record_vendor_expected() {
  local vendor_root="$1"
  [[ -d "$vendor_root" ]] || return 0
  find "$vendor_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r package_dir; do
    local skill_root
    skill_root="$(vendor_skill_root "$package_dir")"
    record_root_skill_names "$skill_root"
  done
}

link_vendor_packages() {
  local vendor_root="$1"
  [[ -d "$vendor_root" ]] || return 0
  find "$vendor_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r package_dir; do
    local skill_root
    skill_root="$(vendor_skill_root "$package_dir")"
    link_root_skill_dirs "$skill_root"
  done
}

prune_unexpected() {
  [[ -d "$SHARED_EXPORT_DIR" ]] || return 0
  find "$SHARED_EXPORT_DIR" -mindepth 1 -maxdepth 1 -type l | while read -r path; do
    local name
    name="$(basename "$path")"
    if ! grep -Fxq -- "$name" "$expected_file" 2>/dev/null; then
      rm -f "$path"
      printf 'PRUNE %s\n' "$path"
    fi
  done
}

ensure_entrypoint_link() {
  local target_path="$1"
  if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$SHARED_EXPORT_DIR" ]]; then
    printf 'OK   %s\n' "$target_path"
    return 0
  fi
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
      printf 'WARN: skip existing path: %s\n' "$target_path" >&2
      return 0
    fi
    rm -rf "$target_path"
  fi
  ensure_dir "$(dirname "$target_path")"
  ln -s "$SHARED_EXPORT_DIR" "$target_path"
  printf 'LINK %s -> %s\n' "$target_path" "$SHARED_EXPORT_DIR"
}

ensure_dir "$SHARED_EXPORT_DIR"
record_root_skill_names "$SKM_DIR/skills"
record_root_skill_names "$SKM_DIR/personal"
record_vendor_expected "$SKM_DIR/vendor"
link_root_skill_dirs "$SKM_DIR/skills"
link_root_skill_dirs "$SKM_DIR/personal"
link_vendor_packages "$SKM_DIR/vendor"
if [[ "$FORCE" -eq 1 ]]; then
  prune_unexpected
fi
ensure_entrypoint_link "$CLAUDE_SKILLS_DIR"
ensure_entrypoint_link "$CODEX_SKILLS_DIR"
