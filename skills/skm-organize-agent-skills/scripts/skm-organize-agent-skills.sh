#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../.." && pwd)"
HOME_DIR="${HOME:?HOME is required}"
SKM_DIR="${SKM_DIR:-$REPO_ROOT}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME_DIR/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME_DIR/.agents/skills}"
LEGACY_CODEX_SKILLS_DIR="${LEGACY_CODEX_SKILLS_DIR:-$HOME_DIR/.codex/skills}"
BOOTSTRAP_SCRIPT="${BOOTSTRAP_SCRIPT:-$REPO_ROOT/scripts/bootstrap.sh}"
CHECK_SCRIPT="${CHECK_SCRIPT:-$REPO_ROOT/scripts/check.sh}"
APPLY=0
declare -a EXTRA_SCAN_ROOTS=()

usage() {
  cat <<'EOF'
Usage: skm-organize-agent-skills.sh [--apply] [--scan-root <path> ...]

Examples:
  skm-organize-agent-skills.sh
  skm-organize-agent-skills.sh --scan-root ~/skills-backup
  skm-organize-agent-skills.sh --apply --scan-root ~/old-skills
EOF
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

normalize_name() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

remember_value() {
  local file="$1"
  local value="$2"
  grep -Fxq -- "$value" "$file" 2>/dev/null || printf '%s\n' "$value" >> "$file"
}

resolve_dir() {
  local path="$1"
  [[ -d "$path" || -L "$path" ]] || return 1
  (
    cd "$path"
    pwd -P
  )
}

canonicalize_dir_if_present() {
  local path="$1"
  resolve_dir "$path" || printf '%s\n' "$path"
}

git_root() {
  local path="$1"
  git -C "$path" rev-parse --show-toplevel 2>/dev/null || return 1
}

iter_skill_dirs() {
  local scan_root="$1"
  [[ -d "$scan_root" || -L "$scan_root" ]] || return 0

  local resolved_root
  resolved_root="$(resolve_dir "$scan_root")" || return 0

  find -L "$resolved_root" -mindepth 1 -maxdepth 5 -type f -name SKILL.md | sort | while read -r skill_file; do
    resolve_dir "$(dirname "$skill_file")"
  done | sort -u
}

is_managed_path() {
  local path="$1"
  case "$path" in
    "$SKM_DIR"/*) return 0 ;;
  esac
  return 1
}

is_tool_owned_path() {
  local path="$1"
  case "$path" in
    "$LEGACY_CODEX_SKILLS_DIR/.system"/*) return 0 ;;
  esac
  return 1
}

print_plan_line() {
  local category="$1"
  local skill_name="$2"
  local source_path="$3"
  local target_path="$4"
  local reason="${5:-}"

  if [[ -n "$reason" ]]; then
    printf 'PLAN %s %s source=%s target=%s reason=%s\n' \
      "$category" "$skill_name" "$source_path" "$target_path" "$reason"
    return
  fi

  printf 'PLAN %s %s source=%s target=%s\n' \
    "$category" "$skill_name" "$source_path" "$target_path"
}

classify_skill_dir() {
  local skill_dir="$1"
  local skill_name
  skill_name="$(basename "$skill_dir")"

  if is_managed_path "$skill_dir"; then
    print_plan_line "ignore" "$skill_name" "$skill_dir" "-" "already-managed"
    return 0
  fi

  if is_tool_owned_path "$skill_dir"; then
    print_plan_line "ignore" "$skill_name" "$skill_dir" "-" "tool-owned"
    return 0
  fi

  local repo_root=""
  repo_root="$(git_root "$skill_dir" || true)"
  if [[ -n "$repo_root" && "$repo_root" != "$SKM_DIR" ]]; then
    local package_name
    package_name="$(normalize_name "$(basename "$repo_root")")"
    print_plan_line "vendor" "$skill_name" "$repo_root" "$SKM_DIR/vendor/$package_name"
    printf 'vendor\t%s\t%s\t%s\n' "$package_name" "$repo_root" "$SKM_DIR/vendor/$package_name"
    return 0
  fi

  print_plan_line "personal" "$skill_name" "$skill_dir" "$SKM_DIR/personal/$skill_name"
  printf 'personal\t%s\t%s\t%s\n' "$skill_name" "$skill_dir" "$SKM_DIR/personal/$skill_name"
}

apply_personal_move() {
  local skill_name="$1"
  local source_dir="$2"
  local target_dir="$3"

  if [[ -e "$target_dir" || -L "$target_dir" ]]; then
    printf 'SKIP personal %s source=%s target=%s reason=target-exists\n' \
      "$skill_name" "$source_dir" "$target_dir"
    return 0
  fi

  mkdir -p "$(dirname "$target_dir")"
  mv "$source_dir" "$target_dir"
  printf 'APPLY personal %s source=%s target=%s\n' \
    "$skill_name" "$source_dir" "$target_dir"
}

apply_vendor_move() {
  local package_name="$1"
  local source_dir="$2"
  local target_dir="$3"

  if [[ -e "$target_dir" || -L "$target_dir" ]]; then
    printf 'SKIP vendor %s source=%s target=%s reason=target-exists\n' \
      "$package_name" "$source_dir" "$target_dir"
    return 0
  fi

  mkdir -p "$(dirname "$target_dir")"
  mv "$source_dir" "$target_dir"
  printf 'APPLY vendor %s source=%s target=%s\n' \
    "$package_name" "$source_dir" "$target_dir"
}

run_apply_phase() {
  local actions_file="$1"
  local applied=0

  while IFS=$'\t' read -r category name source_dir target_dir; do
    [[ -n "${category:-}" ]] || continue
    case "$category" in
      vendor)
        apply_vendor_move "$name" "$source_dir" "$target_dir"
        applied=1
        ;;
      personal)
        apply_personal_move "$name" "$source_dir" "$target_dir"
        applied=1
        ;;
      *)
        fail "unknown action category: $category"
        ;;
    esac
  done < "$actions_file"

  if [[ "$applied" -eq 0 ]]; then
    printf 'NOTE apply: no movable candidates found\n'
    return 0
  fi

  SKM_DIR="$SKM_DIR" \
  CLAUDE_SKILLS_DIR="$CLAUDE_SKILLS_DIR" \
  CODEX_SKILLS_DIR="$CODEX_SKILLS_DIR" \
  bash "$BOOTSTRAP_SCRIPT" --force >/dev/null

  SKM_DIR="$SKM_DIR" \
  CLAUDE_SKILLS_DIR="$CLAUDE_SKILLS_DIR" \
  CODEX_SKILLS_DIR="$CODEX_SKILLS_DIR" \
  bash "$CHECK_SCRIPT" >/dev/null

  printf 'VERIFY check.sh passed\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=1
      ;;
    --scan-root)
      shift
      [[ $# -gt 0 ]] || fail "missing value for --scan-root"
      EXTRA_SCAN_ROOTS+=("$1")
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
  shift
done

SKM_DIR="$(canonicalize_dir_if_present "$SKM_DIR")"
CLAUDE_SKILLS_DIR="$(canonicalize_dir_if_present "$CLAUDE_SKILLS_DIR")"
CODEX_SKILLS_DIR="$(canonicalize_dir_if_present "$CODEX_SKILLS_DIR")"
LEGACY_CODEX_SKILLS_DIR="$(canonicalize_dir_if_present "$LEGACY_CODEX_SKILLS_DIR")"

seen_skill_dirs="$(mktemp)"
actions_file="$(mktemp)"
trap 'rm -f "$seen_skill_dirs" "$actions_file"' EXIT

declare -a scan_roots=(
  "$CODEX_SKILLS_DIR"
  "$CLAUDE_SKILLS_DIR"
  "$LEGACY_CODEX_SKILLS_DIR"
)
scan_roots+=("${EXTRA_SCAN_ROOTS[@]}")

if [[ "$APPLY" -eq 1 ]]; then
  printf 'MODE apply\n'
else
  printf 'MODE dry-run\n'
fi

for scan_root in "${scan_roots[@]}"; do
  while read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    if grep -Fxq -- "$skill_dir" "$seen_skill_dirs" 2>/dev/null; then
      continue
    fi
    remember_value "$seen_skill_dirs" "$skill_dir"

    classification="$(classify_skill_dir "$skill_dir")"
    printf '%s\n' "$classification" | while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      if [[ "$line" == PLAN* ]]; then
        printf '%s\n' "$line"
      else
        remember_value "$actions_file" "$line"
      fi
    done
  done < <(iter_skill_dirs "$scan_root")
done

if [[ "$APPLY" -eq 1 ]]; then
  run_apply_phase "$actions_file"
fi
