---
name: release-agent-skill-pack
description: Use when a local agent skill pack is ready to become a standalone GitHub repository and you want to validate its structure, frontmatter, and release readiness, then generate a first-release checklist.
---

# Release Agent Skill Pack

## Overview

This skill prepares a local skill pack for first release.

It does not publish directly. Instead, it validates the repository and generates a concrete release checklist so the final publish step is predictable.

## When to Use

Use this skill when:

- a local skill pack is about to become its own repository
- you want to check README, skill structure, and frontmatter before publishing
- you want a reusable release checklist instead of ad-hoc notes

Do not use this skill for updating an already installed vendor package. Use `update-vendor-skills` for that.

## Core Rule

Before release:

1. validate the pack structure
2. validate every `SKILL.md`
3. generate a first-release checklist

Run:

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/release-agent-skill-pack/scripts/release-agent-skill-pack.sh <repo-path>
```

## Workflow

### 1. Point it at the target repository

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/release-agent-skill-pack/scripts/release-agent-skill-pack.sh \
  /path/to/skill-pack
```

### 2. Review validation output

The script reports:

- `PASS readme`
- `PASS skills-dir`
- `PASS skill <name>`
- `CHECKLIST <path>`

### 3. Use the generated checklist

The script writes `RELEASE-CHECKLIST.md` in the target repo root.

Use it to review:

- repo messaging
- skill names and descriptions
- structure and scripts
- first publish steps

## Common Mistakes

- publishing a repo without a README
- mixing unrelated tooling with the skill pack itself
- shipping invalid or weak `SKILL.md` frontmatter
- skipping a final checklist and relying on memory

## Completion Checklist

1. repository passes structural validation
2. checklist file is generated
3. remaining publish actions are visible in one place
