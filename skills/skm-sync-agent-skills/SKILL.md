---
name: skm-sync-agent-skills
description: Use when the declared skill layout under `~/.skm` and the live entrypoints in `~/.agents/skills` or `~/.claude/skills` may be out of sync, and you want to rebuild missing links while removing stale or unmanaged symlinks.
---

# Sync Agent Skills

## Overview

This skill forces the runtime entrypoints back into alignment with the `skm` source of truth.

Use it when the current state is messy but you already trust the managed source tree.

## When to Use

Use this skill when:

- stale entrypoint links keep reappearing
- `Codex` or `Claude Code` are exposing the wrong set of skills
- unmanaged symlinks exist in `~/.agents/skills` or `~/.claude/skills`
- you want to reconcile the current runtime state to the declared layout
- you created a new skill under `~/.skm/personal` and the runtime layer has not picked it up yet

Do not use this skill to discover new external packages. Use `skm-install-linked-agent-skills` for that.
Do not use this skill to force through duplicate skill-name conflicts. Resolve those with `skm-doctor-agent-skills` or `skm-organize-agent-skills` first.

## Core Rule

Sync means:

1. remove symlink entries not declared by `skm`
2. rebuild the expected entrypoints
3. verify the rebuilt state

Run:

```bash
bash ~/.skm/skills/skm-sync-agent-skills/scripts/skm-sync-agent-skills.sh
```

## Important Reminder

Sync repairs the runtime entrypoints. It does **not** hot-reload the skill inventory of an already-running `Codex` session.

If a newly created skill still does not appear after sync:

1. verify `check.sh` passes
2. start a new `Codex` session

## Workflow

### 1. Diagnose if needed

If you are not sure what is wrong, run `skm-doctor-agent-skills` first.

If `doctor` reports `CONFLICT`, stop there. Sync should not proceed until the duplicate declared sources are resolved.

### 2. Run sync

```bash
bash ~/.skm/skills/skm-sync-agent-skills/scripts/skm-sync-agent-skills.sh
```

### 3. Read the diff-style output

The script reports:

- `ADDED <layer> <name>`
- `REMOVED <layer> <name>`

Then it runs:

- `bootstrap.sh --force`
- `check.sh`

If duplicate skill names exist across declared sources, sync now aborts instead of silently choosing one source.

If the script succeeds but the current session still cannot see a new skill, that is a session-refresh issue rather than a sync failure.

## Common Mistakes

- Running sync when the source tree itself is wrong
- Running sync when `doctor` has already reported `CONFLICT`
- Expecting unmanaged symlinks to survive a sync
- Treating entrypoint directories as editable source directories

## Completion Checklist

1. stale links are removed
2. expected links are present again
3. `check.sh` passes
