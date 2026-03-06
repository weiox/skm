---
name: sync-agent-skills
description: Use when the declared skill layout under `~/.dotfiles/.config/agent-hub/skills` and the live entrypoints in `~/.agents/skills` or `~/.claude/skills` may be out of sync, and you want to rebuild missing links while removing stale or unmanaged symlinks.
---

# Sync Agent Skills

## Overview

This skill forces the runtime entrypoints back into alignment with the `agent-hub` source of truth.

Use it when the current state is messy but you already trust the managed source tree.

## When to Use

Use this skill when:

- stale entrypoint links keep reappearing
- `Codex` or `Claude Code` are exposing the wrong set of skills
- unmanaged symlinks exist in `~/.agents/skills` or `~/.claude/skills`
- you want to reconcile the current runtime state to the declared layout

Do not use this skill to discover new external packages. Use `install-linked-agent-skills` for that.

## Core Rule

Sync means:

1. remove symlink entries not declared by `agent-hub`
2. rebuild the expected entrypoints
3. verify the rebuilt state

Run:

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skill-init/skills/sync-agent-skills/scripts/sync-agent-skills.sh
```

## Workflow

### 1. Diagnose if needed

If you are not sure what is wrong, run `doctor-agent-skills` first.

### 2. Run sync

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skill-init/skills/sync-agent-skills/scripts/sync-agent-skills.sh
```

### 3. Read the diff-style output

The script reports:

- `ADDED <layer> <name>`
- `REMOVED <layer> <name>`

Then it runs:

- `bootstrap.sh --force`
- `check.sh`

## Common Mistakes

- Running sync when the source tree itself is wrong
- Expecting unmanaged symlinks to survive a sync
- Treating entrypoint directories as editable source directories

## Completion Checklist

1. stale links are removed
2. expected links are present again
3. `check.sh` passes
