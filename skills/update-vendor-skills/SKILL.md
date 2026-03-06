---
name: update-vendor-skills
description: Use when vendor skill packages under `~/.dotfiles/.config/agent-hub/skills/vendor` may have upstream updates and you want to refresh one package or all packages, then rebuild and verify the Codex and Claude Code entrypoints.
---

# Update Vendor Skills

## Overview

Vendor skill packages drift over time. This skill updates those packages without losing the local `agent-hub` entrypoint model.

After updating a vendor package, it immediately rebuilds the entrypoints and verifies the result.

## When to Use

Use this skill when:

- a vendor package has upstream changes you want locally
- a submodule is behind remote
- you imported a package earlier and now want to refresh it
- you want to update all vendor packages in one pass

Do not use this skill for first-time installation of a new package. Use `install-linked-agent-skills` for that.

## Core Rule

After every vendor update:

1. rebuild entrypoints
2. verify entrypoints

Run the bundled script:

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skill-init/skills/update-vendor-skills/scripts/update-vendor-skills.sh [package-name...]
```

## Workflow

### 1. Choose scope

- no arguments: update all vendor packages
- one argument: update one vendor package
- multiple arguments: update only the named packages

### 2. Run the updater

Examples:

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skill-init/skills/update-vendor-skills/scripts/update-vendor-skills.sh

bash ~/.dotfiles/.config/agent-hub/skills/vendor/skill-init/skills/update-vendor-skills/scripts/update-vendor-skills.sh superpowers

bash ~/.dotfiles/.config/agent-hub/skills/vendor/skill-init/skills/update-vendor-skills/scripts/update-vendor-skills.sh superpowers skill-init
```

### 3. Read the result

The script reports one of:

- `UPDATED <package>`
- `UNCHANGED <package>`
- `SKIP <package>`

Then it runs:

- `bootstrap.sh --force`
- `check.sh`

## Common Mistakes

- pulling a vendor package manually and forgetting to rebuild entrypoints
- editing vendor packages directly in entrypoint directories
- using install flow for updates instead of using the updater
- assuming vendor updates do not affect `Codex` or `Claude Code` visibility

## Completion Checklist

Before calling the update complete:

1. target vendor packages have been refreshed
2. `bootstrap.sh --force` has run
3. `check.sh` passes
4. updated packages are clearly reported back to the user
