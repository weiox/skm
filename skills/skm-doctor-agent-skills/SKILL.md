---
name: skm-doctor-agent-skills
description: Use when agent skill entrypoints for Codex and Claude Code may be broken, duplicated, unmanaged, or drifting away from `~/.skm`, and you want a structured diagnosis before fixing anything.
---

# Doctor Agent Skills

## Overview

Before reorganizing or reinstalling skills, inspect the current state first.

This skill diagnoses the two entrypoint layers:

- `~/.agents/skills`
- `~/.claude/skills`

and checks whether they are still aligned with the managed source tree under `~/.skm`.

## When to Use

Use this skill when:

- a skill is visible in one agent but not the other
- old symlinks keep showing up after reorganizing
- you suspect broken links or unmanaged links
- you want a quick health check before running larger migrations
- you just created a new skill under `~/.skm/personal` and it still does not show up in `Codex` or `Claude Code`

Do not use this skill for project-specific repository guidance or for installing new skills from links.

## Core Rule

Diagnose first, then fix.

Run the doctor script before making cleanup changes:

```bash
bash ~/.skm/skills/skm-doctor-agent-skills/scripts/skm-doctor-agent-skills.sh
```

## What It Reports

The script classifies each entrypoint symlink as:

- `OK` — managed and resolves inside `skm`
- `BROKEN` — symlink exists but target does not
- `UNMANAGED` — symlink points outside the managed `skm` tree
- `CONFLICT` — more than one declared skill source shares the same skill name

## Common Visibility Pitfalls

- In this setup, `Codex` runtime discovery comes from `~/.agents/skills`, not from `~/.codex/skills`.
- Creating a skill under `~/.skm/personal` is not enough by itself; the export and entrypoint layers still need to be rebuilt.
- A clean doctor result only says the runtime links are structurally healthy. It does not refresh the skill list inside an already-running `Codex` session.

## Workflow

### 1. Run the doctor

```bash
bash ~/.skm/skills/skm-doctor-agent-skills/scripts/skm-doctor-agent-skills.sh
```

### 2. Read the categories

- If you see `BROKEN`, rebuild or remove stale entrypoints
- If you see `UNMANAGED`, decide whether the entry should move into `skm`
- If you see `CONFLICT`, stop and resolve the duplicate source-of-truth problem before running sync
- If everything is `OK`, the entrypoint layer is at least structurally healthy
- If the structure is healthy but a newly created skill is still missing, run `skm-sync-agent-skills` and then start a new `Codex` session

### 3. Apply the next skill

After diagnosis:

- use `skm-organize-agent-skills` when source-of-truth layout is wrong
- use `skm-install-linked-agent-skills` when a vendor package is missing
- use `bootstrap.sh --force` when the source is correct and only the entrypoints need rebuilding

## Common Mistakes

- Fixing links blindly before inspecting current state
- Treating any symlink as healthy just because it exists
- Leaving unmanaged links in `~/.agents/skills` or `~/.claude/skills`
- Ignoring duplicate skill names across `skills/`, `personal/`, and `vendor/`
- Assuming `Codex` and `Claude Code` should always expose the same shape of entrypoints

## Completion Checklist

Before calling the diagnosis complete:

1. the doctor script has run on the current machine
2. broken, unmanaged, conflicting, and healthy states are clearly distinguished
3. the next remediation step is chosen based on the diagnosis output
