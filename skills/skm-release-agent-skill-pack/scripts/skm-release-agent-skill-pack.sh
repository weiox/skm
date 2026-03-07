#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: skm-release-agent-skill-pack.sh <repo-path>
EOF
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

validate_frontmatter() {
  local skill_file="$1"
  local expected_dir_name="$2"

  local name description
  name="$(awk 'BEGIN{inblock=0} /^---$/ {if(inblock==0){inblock=1; next}else{exit}} inblock==1 && /^name:[[:space:]]*/ {sub(/^name:[[:space:]]*/, ""); print; exit}' "$skill_file")"
  description="$(awk 'BEGIN{inblock=0} /^---$/ {if(inblock==0){inblock=1; next}else{exit}} inblock==1 && /^description:[[:space:]]*/ {sub(/^description:[[:space:]]*/, ""); print; exit}' "$skill_file")"

  [[ -n "$name" ]] || fail "missing frontmatter name in $skill_file"
  [[ "$name" == "$expected_dir_name" ]] || fail "skill dir name mismatch in $skill_file (expected $expected_dir_name, got $name)"
  [[ -n "$description" ]] || fail "missing frontmatter description in $skill_file"
  [[ "$description" == Use\ when* ]] || fail "description should start with 'Use when' in $skill_file"
}

main() {
  [[ $# -eq 1 ]] || {
    usage
    exit 1
  }

  local repo_root="$1"
  [[ -d "$repo_root" ]] || fail "repo path not found: $repo_root"

  local readme="$repo_root/README.md"
  local skills_root="$repo_root/skills"
  local checklist="$repo_root/RELEASE-CHECKLIST.md"

  [[ -f "$readme" ]] || fail "missing README.md"
  printf 'PASS readme\n'

  [[ -d "$skills_root" ]] || fail "missing skills directory"
  printf 'PASS skills-dir\n'

  local skill_count=0
  find "$skills_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r skill_dir; do
    local skill_name skill_file
    skill_name="$(basename "$skill_dir")"
    skill_file="$skill_dir/SKILL.md"
    [[ -f "$skill_file" ]] || fail "missing SKILL.md for $skill_name"
    validate_frontmatter "$skill_file" "$skill_name"
    printf 'PASS skill %s\n' "$skill_name"
  done

  skill_count="$(find "$skills_root" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  [[ "$skill_count" -gt 0 ]] || fail "no skills found in $skills_root"

  cat > "$checklist" <<EOF
# Release Checklist

Repository: $(basename "$repo_root")

## Validation

- [x] README exists
- [x] skills directory exists
- [x] Detected $skill_count skill(s)

## Review README messaging

- [ ] Confirm repository title and summary match the actual skill pack scope
- [ ] Confirm installation instructions are accurate
- [ ] Confirm examples use current paths and command names

## Review skills

$(find "$skills_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r skill_dir; do
  printf -- '- [ ] Review `%s` frontmatter, triggers, and examples\n' "$(basename "$skill_dir")"
done)

## Release steps

- [ ] Commit final changes
- [ ] Push default branch
- [ ] Add repository description and topics on GitHub
- [ ] Verify the pack can be consumed from \`skills/vendor/\`
EOF

  printf 'CHECKLIST %s\n' "$checklist"
}

main "$@"
