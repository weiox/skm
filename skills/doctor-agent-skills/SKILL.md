---
name: doctor-agent-skills
description: Use when agent skill entrypoints for Codex and Claude Code may be broken, duplicated, unmanaged, or drifting away from `~/.dotfiles/.config/agent-hub/skills`, and you want a structured diagnosis before fixing anything.
---

# Doctor Agent Skills

## Overview

Before reorganizing or reinstalling skills, inspect the current state first.

This skill diagnoses the two entrypoint layers:

- `~/.agents/skills`
- `~/.claude/skills`

and checks whether they are still aligned with the managed source tree under `~/.dotfiles/.config/agent-hub/skills`.

## When to Use

Use this skill when:

- a skill is visible in one agent but not the other
- old symlinks keep showing up after reorganizing
- you suspect broken links or unmanaged links
- you want a quick health check before running larger migrations

Do not use this skill for project-specific repository guidance or for installing new skills from links.

## Core Rule

Diagnose first, then fix.

Run the doctor script before making cleanup changes:

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/doctor-agent-skills/scripts/doctor-agent-skills.sh
```

## What It Reports

The script classifies each entrypoint symlink as:

- `OK` — managed and resolves inside `agent-hub`
- `BROKEN` — symlink exists but target does not
- `UNMANAGED` — symlink points outside the managed `agent-hub` tree

## Workflow

### 1. Run the doctor

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/doctor-agent-skills/scripts/doctor-agent-skills.sh
```

### 2. Read the categories

- If you see `BROKEN`, rebuild or remove stale entrypoints
- If you see `UNMANAGED`, decide whether the entry should move into `agent-hub`
- If everything is `OK`, the entrypoint layer is at least structurally healthy

### 3. Apply the next skill

After diagnosis:

- use `organize-agent-skills` when source-of-truth layout is wrong
- use `install-linked-agent-skills` when a vendor package is missing
- use `bootstrap.sh --force` when the source is correct and only the entrypoints need rebuilding

## Common Mistakes

- Fixing links blindly before inspecting current state
- Treating any symlink as healthy just because it exists
- Leaving unmanaged links in `~/.agents/skills` or `~/.claude/skills`
- Assuming `Codex` and `Claude Code` should always expose the same shape of entrypoints

## Completion Checklist

Before calling the diagnosis complete:

1. the doctor script has run on the current machine
2. broken, unmanaged, and healthy links are clearly distinguished
3. the next remediation step is chosen based on the diagnosis output
