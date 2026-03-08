---
name: skm-organize-agent-skills
description: Use when local skills for Codex and Claude Code are scattered across `~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills`, or ad-hoc folders and you want to consolidate them into a single source of truth under `~/.skm` while keeping tool-specific symlink entrypoints.
---

# Organize Agent Skills

## Overview

Keep one source of truth for local skills, and treat every tool-specific skill directory as an entrypoint, not as the place you maintain content.

The target model is:

- Source of truth: `~/.skm`
- `Codex` entrypoint: `~/.agents/skills`
- `Claude Code` entrypoint: `~/.claude/skills`

## When to Use

Use this skill when you notice any of these symptoms:

- the same skill exists in more than one place
- `Codex` can see a skill but `Claude Code` cannot, or the reverse
- you are migrating to a new machine and want GitHub-backed reuse
- personal skills and third-party skills are mixed together
- you want to reduce manual symlink sprawl or one-off local edits

Do not use this skill for project-specific instructions like repository `AGENTS.md` or `CLAUDE.md`.

## Target Layout

Keep the repository layout minimal:

```text
~/.skm/
├── personal/
│   └── <skill-name>/
│       └── SKILL.md
└── vendor/
    └── <package>/
```

Apply these rules:

- your own reusable skills go in `~/.skm/personal/`
- third-party skill packs go in `~/.skm/vendor/`
- `~/.agents/skills` and `~/.claude/skills` should contain symlinks only
- do not treat `~/.codex/skills/.system` or runtime caches as part of your personal library

## Workflow

### 1. Inventory everything first

Start with the bundled dry-run inventory:

```bash
bash ~/.skm/skills/skm-organize-agent-skills/scripts/skm-organize-agent-skills.sh
```

If you also want to inspect an ad-hoc folder of old skills, add one or more scan roots:

```bash
bash ~/.skm/skills/skm-organize-agent-skills/scripts/skm-organize-agent-skills.sh \
  --scan-root ~/old-skills \
  --scan-root ~/Downloads/skill-backups
```

The script classifies each discovered item into exactly one bucket:

- **personal**: you own the content and want to maintain it
- **vendor**: upstream package you want to track separately
- **ignore**: runtime files, tool internals, obsolete duplicates

### 2. Consolidate personal skills

Review the dry-run output first. When the plan looks correct, apply it explicitly:

```bash
bash ~/.skm/skills/skm-organize-agent-skills/scripts/skm-organize-agent-skills.sh \
  --apply \
  --scan-root ~/old-skills
```

In apply mode, the script:

1. moves personal skills into `~/.skm/personal/<skill-name>/`
2. moves git-backed upstream packs into `~/.skm/vendor/<package>/`
3. runs `bootstrap.sh --force`
4. runs `check.sh`

### 3. Consolidate vendor skills

For third-party skill packs:

- prefer `git submodule` under `~/.skm/vendor/`
- keep the upstream package intact instead of copying individual files by hand
- let `bootstrap.sh` expose vendor skills to the agent entrypoints
- treat a git-backed external repo as a vendor package, not as a personal skill

Example:

```bash
bash ~/.skm/skills/skm-organize-agent-skills/scripts/skm-organize-agent-skills.sh \
  --scan-root ~/src/superpowers
```

### 4. Verify the entrypoints

After apply mode runs, confirm the generated entrypoints:

```bash
bash ~/.skm/scripts/check.sh
```

Also spot-check the symlinks:

```bash
find ~/.agents/skills -maxdepth 2 -type l | sort
find ~/.claude/skills -maxdepth 2 -type l | sort
```

## Quick Decisions

Use this table when classifying a skill:

| Situation | Destination |
| --- | --- |
| You wrote it and will maintain it | `~/.skm/personal/<skill-name>/` |
| It comes from an upstream package | `~/.skm/vendor/<package>/` |
| It is tool-generated or runtime-only | Do not store in `skm` |
| It is repo-specific guidance | Keep it in the repo, not here |

## Common Mistakes

- Editing `~/.agents/skills` or `~/.claude/skills` as if they were source directories
- Keeping duplicate copies of the same skill in multiple source locations
- Copying third-party packs manually instead of preserving an upstream boundary
- Treating `~/.codex/skills/.system` or chat history as versioned personal assets
- Forgetting to rerun `bootstrap.sh` and `check.sh` after a reorganization

## Completion Checklist

Before calling the reorganization done:

1. every maintained skill lives under `~/.skm`
2. personal skills exist only under `~/.skm/personal/`
3. vendor packs exist only under `~/.skm/vendor/`
4. `~/.agents/skills` and `~/.claude/skills` are regenerated symlink entrypoints
5. `bash ~/.skm/scripts/check.sh` passes
