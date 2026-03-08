#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

bash "$REPO_ROOT/skills/skm-doctor-agent-skills/scripts/test-skm-doctor-agent-skills.sh"
bash "$REPO_ROOT/skills/skm-organize-agent-skills/scripts/test-skm-organize-agent-skills.sh"
bash "$REPO_ROOT/tests/test-bootstrap.sh"
bash "$REPO_ROOT/tests/test-sync.sh"
bash "$REPO_ROOT/tests/test-install-linked-skill.sh"
bash "$REPO_ROOT/tests/test-update-vendor-skills.sh"
