#!/usr/bin/env bash

set -euo pipefail

HOME_DIR="${HOME:?HOME is required}"
SKM_DIR="${SKM_DIR:-$HOME_DIR/.skm}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME_DIR/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME_DIR/.agents/skills}"

resolve_dir() {
  local path="$1"
  [[ -d "$path" ]] || return 1
  (
    cd "$path"
    pwd -P
  )
}

canonicalize_dir_if_present() {
  local path="$1"
  resolve_dir "$path" || printf '%s\n' "$path"
}

iter_skill_dirs() {
  local source_root="$1"
  [[ -d "$source_root" ]] || return 0
  find "$source_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r skill_dir; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    resolve_dir "$skill_dir"
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

sources_file="$(mktemp)"
trap 'rm -f "$sources_file"' EXIT

remember_skill_source() {
  local entry_name="$1"
  local source_dir="$2"
  printf '%s\t%s\n' "$entry_name" "$source_dir" >> "$sources_file"
}

scan_root_for_conflicts() {
  local source_root="$1"
  while read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    remember_skill_source "$(basename "$skill_dir")" "$skill_dir"
  done < <(iter_skill_dirs "$source_root")
}

scan_vendor_for_conflicts() {
  local vendor_root="$1"
  [[ -d "$vendor_root" ]] || return 0
  find "$vendor_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r package_dir; do
    local skill_root
    skill_root="$(vendor_skill_root "$package_dir")"
    scan_root_for_conflicts "$skill_root"
  done
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

inspect_dir() {
  local label="$1"
  local target_dir="$2"
  local resolved_dir

  resolved_dir="$(resolve_dir "$target_dir")" || return 0

  find "$resolved_dir" -mindepth 1 -maxdepth 1 -type l | sort | while read -r path; do
    local name target resolved_target
    name="$(basename "$path")"
    target="$(readlink "$path" 2>/dev/null || true)"

    if [[ -z "$target" ]]; then
      printf 'BROKEN %s %s -> <unreadable>\n' "$label" "$name"
      continue
    fi

    if [[ ! -e "$target" && ! -L "$target" ]]; then
      printf 'BROKEN %s %s -> %s\n' "$label" "$name" "$target"
      continue
    fi

    resolved_target="$(canonicalize_dir_if_present "$target")"

    case "$resolved_target" in
      "$SKM_DIR"/*)
        printf 'OK %s %s -> %s\n' "$label" "$name" "$resolved_target"
        ;;
      *)
        printf 'UNMANAGED %s %s -> %s\n' "$label" "$name" "$resolved_target"
        ;;
    esac
  done
}

SKM_DIR="$(canonicalize_dir_if_present "$SKM_DIR")"
CLAUDE_SKILLS_DIR="$(canonicalize_dir_if_present "$CLAUDE_SKILLS_DIR")"
CODEX_SKILLS_DIR="$(canonicalize_dir_if_present "$CODEX_SKILLS_DIR")"
scan_root_for_conflicts "$SKM_DIR/skills"
scan_root_for_conflicts "$SKM_DIR/personal"
scan_vendor_for_conflicts "$SKM_DIR/vendor"
print_conflicts
inspect_dir "codex" "$CODEX_SKILLS_DIR"
inspect_dir "claude" "$CLAUDE_SKILLS_DIR"
