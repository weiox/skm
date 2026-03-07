#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKM_DIR="${SKM_DIR:-$(cd "$SKILL_DIR/../.." && pwd)}"
VENDOR_ROOT="$SKM_DIR/vendor"

usage() {
  cat <<'EOF'
Usage: skm-install-linked-skill.sh <link> [vendor-name]

Examples:
  skm-install-linked-skill.sh "https://github.com/owner/repo"
  skm-install-linked-skill.sh "https://skills.sh/owner/repo/skill-name"
  skm-install-linked-skill.sh "owner/repo@skill-name" custom-name
  skm-install-linked-skill.sh "/path/to/local/git/repo" local-pack
EOF
}

log() {
  printf '%s\n' "$*"
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

derive_from_skills_sh() {
  local link="$1"
  local rest="${link#https://skills.sh/}"
  local owner="${rest%%/*}"
  rest="${rest#*/}"
  local repo="${rest%%/*}"
  [[ -n "$owner" && -n "$repo" && "$owner" != "$rest" ]] || return 1
  printf 'https://github.com/%s/%s.git\n%s\n' "$owner" "$repo" "$repo"
}

derive_from_github_https() {
  local link="$1"
  local rest="${link#https://github.com/}"
  local owner="${rest%%/*}"
  rest="${rest#*/}"
  local repo="${rest%%/*}"
  repo="${repo%.git}"
  [[ -n "$owner" && -n "$repo" && "$owner" != "$rest" ]] || return 1
  printf 'https://github.com/%s/%s.git\n%s\n' "$owner" "$repo" "$repo"
}

derive_from_github_ssh() {
  local link="$1"
  local rest="${link#git@github.com:}"
  local owner="${rest%%/*}"
  rest="${rest#*/}"
  local repo="${rest%.git}"
  [[ -n "$owner" && -n "$repo" && "$owner" != "$rest" ]] || return 1
  printf '%s\n%s\n' "$link" "$repo"
}

derive_from_owner_repo() {
  local link="$1"
  local spec="${link%@*}"
  local owner="${spec%%/*}"
  local repo="${spec#*/}"
  [[ -n "$owner" && -n "$repo" && "$owner" != "$spec" ]] || return 1
  printf 'https://github.com/%s/%s.git\n%s\n' "$owner" "$repo" "$repo"
}

derive_from_local_path() {
  local link="$1"
  local path="$link"
  if [[ "$path" == file://* ]]; then
    path="${path#file://}"
  fi

  [[ -d "$path" ]] || return 1
  [[ -d "$path/.git" ]] || return 1

  local repo
  repo="$(basename "$path")"
  printf '%s\n%s\n' "$path" "$repo"
}

parse_link() {
  local link="$1"

  if [[ "$link" == https://skills.sh/* ]]; then
    derive_from_skills_sh "$link"
    return
  fi

  if [[ "$link" == https://github.com/* ]]; then
    derive_from_github_https "$link"
    return
  fi

  if [[ "$link" == git@github.com:* ]]; then
    derive_from_github_ssh "$link"
    return
  fi

  if [[ "$link" == */* && "$link" != /* && "$link" != ./* && "$link" != ../* ]]; then
    derive_from_owner_repo "$link"
    return
  fi

  derive_from_local_path "$link"
}

has_skill_content() {
  local package_dir="$1"
  local root="$package_dir"
  if [[ -d "$package_dir/skills" ]]; then
    root="$package_dir/skills"
  fi

  find "$root" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/SKILL.md' ';' -print -quit | grep -q .
}

ensure_git_repo() {
  git -C "$SKM_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "$SKM_DIR is not a git repository"
}

main() {
  [[ $# -ge 1 ]] || {
    usage
    exit 1
  }

  local link="$1"
  local package_name="${2:-}"
  local parsed repo_url inferred_name
  parsed="$(parse_link "$link")" || fail "unsupported link: $link"
  repo_url="$(printf '%s\n' "$parsed" | sed -n '1p')"
  inferred_name="$(printf '%s\n' "$parsed" | sed -n '2p')"

  if [[ -z "$package_name" ]]; then
    package_name="$inferred_name"
  fi
  package_name="$(normalize_name "$package_name")"
  [[ -n "$package_name" ]] || fail "could not derive vendor package name"

  ensure_git_repo
  mkdir -p "$VENDOR_ROOT"

  local relative_submodule="vendor/$package_name"
  local target_dir="$SKM_DIR/$relative_submodule"
  local status="installed"

  if [[ -e "$target_dir" ]]; then
    if [[ -d "$target_dir/.git" || -f "$target_dir/.git" ]]; then
      status="already-present"
    else
      fail "target path exists and is not a git repo: $target_dir"
    fi
  else
    git -C "$SKM_DIR" -c protocol.file.allow=always submodule add --quiet "$repo_url" "$relative_submodule" >/dev/null
  fi

  git -C "$SKM_DIR" -c protocol.file.allow=always submodule update --init --recursive --quiet "$relative_submodule" >/dev/null

  has_skill_content "$target_dir" || fail "imported package has no discoverable skills: $target_dir"

  bash "$SKM_DIR/scripts/bootstrap.sh" --force >/dev/null
  bash "$SKM_DIR/scripts/check.sh" >/dev/null

  log "STATUS: $status"
  log "PACKAGE: $package_name"
  log "TARGET: $target_dir"
  log "SHARED_EXPORT: $HOME/.skm/exports/shared"
}

main "$@"
