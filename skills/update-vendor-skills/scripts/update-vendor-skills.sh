#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENT_HUB_ROOT="${AGENT_HUB_ROOT:-$(cd "$SKILL_DIR/../../../../.." && pwd)}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$AGENT_HUB_ROOT/../.." && pwd)}"
VENDOR_ROOT="$AGENT_HUB_ROOT/skills/vendor"
BOOTSTRAP_SCRIPT="$AGENT_HUB_ROOT/scripts/bootstrap.sh"
CHECK_SCRIPT="$AGENT_HUB_ROOT/scripts/check.sh"
SELF_PACKAGE="skill-init"

usage() {
  cat <<'EOF'
Usage: update-vendor-skills.sh [package-name...]

Examples:
  update-vendor-skills.sh
  update-vendor-skills.sh superpowers
  update-vendor-skills.sh superpowers skill-init
EOF
}

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

is_submodule_path() {
  local relative_path="$1"
  git -C "$DOTFILES_ROOT" config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null \
    | awk '{print $2}' | grep -Fxq -- "$relative_path"
}

update_package() {
  local package_name="$1"
  local package_dir="$VENDOR_ROOT/$package_name"
  [[ -d "$package_dir" ]] || fail "vendor package not found: $package_name"

  local before after relative_path
  relative_path=".config/agent-hub/skills/vendor/$package_name"

  if [[ ! -d "$package_dir/.git" && ! -f "$package_dir/.git" ]]; then
    log "SKIP $package_name (not a git package)"
    return 0
  fi

  before="$(git -C "$package_dir" rev-parse HEAD)"

  if is_submodule_path "$relative_path"; then
    git -C "$DOTFILES_ROOT" -c protocol.file.allow=always submodule update --remote --init --recursive -- "$relative_path" >/dev/null
  else
    git -C "$package_dir" pull --ff-only >/dev/null
  fi

  after="$(git -C "$package_dir" rev-parse HEAD)"

  if [[ "$before" == "$after" ]]; then
    log "UNCHANGED $package_name"
  else
    log "UPDATED $package_name"
  fi
}

collect_packages() {
  if [[ "$#" -gt 0 ]]; then
    printf '%s\n' "$@"
    return
  fi

  find "$VENDOR_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | while read -r package_dir; do
    local package_name
    package_name="$(basename "$package_dir")"
    if [[ "$package_name" == "$SELF_PACKAGE" ]]; then
      log "SKIP $package_name (self-update requires explicit target)" >&2
      continue
    fi
    printf '%s\n' "$package_name"
  done
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  [[ -d "$VENDOR_ROOT" ]] || fail "vendor root not found: $VENDOR_ROOT"

  while read -r package_name; do
    [[ -n "$package_name" ]] || continue
    update_package "$package_name"
  done < <(collect_packages "$@")

  bash "$BOOTSTRAP_SCRIPT" --force >/dev/null
  bash "$CHECK_SCRIPT" >/dev/null
}

main "$@"
