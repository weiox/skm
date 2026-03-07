#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: extract-agent-skill-pack.sh <source-root> <target-repo> <skill-name...>
EOF
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

copy_skill() {
  local source_root="$1"
  local target_repo="$2"
  local skill_name="$3"

  local source_dir="$source_root/$skill_name"
  local target_dir="$target_repo/skills/$skill_name"

  [[ -d "$source_dir" ]] || fail "missing source skill directory: $source_dir"
  [[ -f "$source_dir/SKILL.md" ]] || fail "missing SKILL.md for $skill_name"
  [[ ! -e "$target_dir" ]] || fail "target skill already exists: $target_dir"

  cp -R "$source_dir" "$target_dir"
  printf 'EXTRACTED %s\n' "$skill_name"
}

main() {
  [[ $# -ge 3 ]] || {
    usage
    exit 1
  }

  local source_root="$1"
  local target_repo="$2"
  shift 2
  local skill_names=("$@")

  [[ -d "$source_root" ]] || fail "source root not found: $source_root"

  mkdir -p "$target_repo/skills"

  if [[ ! -d "$target_repo/.git" ]]; then
    git -C "$target_repo" init -q >/dev/null
  fi

  if [[ ! -f "$target_repo/README.md" ]]; then
    cat > "$target_repo/README.md" <<EOF
# $(basename "$target_repo")

Extracted agent skill pack.
EOF
  fi

  for skill_name in "${skill_names[@]}"; do
    copy_skill "$source_root" "$target_repo" "$skill_name"
  done

  cat > "$target_repo/EXTRACT-CHECKLIST.md" <<EOF
# Extract Checklist

Target pack: $(basename "$target_repo")

## Extracted skills

$(for skill_name in "${skill_names[@]}"; do
  printf -- '- [x] `%s`\n' "$skill_name"
done)

## Next steps

- [ ] Review extracted files and remove anything pack-specific that should stay behind
- [ ] Run \`release-agent-skill-pack\` on this repository
- [ ] Create or connect a remote repository
- [ ] Reconnect the released repository through \`skills/vendor/\`
- [ ] Remove original source copies only after the new vendor package is live
EOF

  printf 'CHECKLIST %s\n' "$target_repo/EXTRACT-CHECKLIST.md"
}

main "$@"
