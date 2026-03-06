#!/usr/bin/env bash

set -euo pipefail

HOME_DIR="${HOME:?HOME is required}"
AGENT_HUB_ROOT="${AGENT_HUB_ROOT:-$HOME_DIR/.dotfiles/.config/agent-hub}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME_DIR/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME_DIR/.agents/skills}"

inspect_dir() {
  local label="$1"
  local target_dir="$2"

  [[ -d "$target_dir" ]] || return 0

  find "$target_dir" -mindepth 1 -maxdepth 1 -type l | sort | while read -r path; do
    local name target
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

    case "$target" in
      "$AGENT_HUB_ROOT"/*)
        printf 'OK %s %s -> %s\n' "$label" "$name" "$target"
        ;;
      *)
        printf 'UNMANAGED %s %s -> %s\n' "$label" "$name" "$target"
        ;;
    esac
  done
}

inspect_dir "codex" "$CODEX_SKILLS_DIR"
inspect_dir "claude" "$CLAUDE_SKILLS_DIR"
