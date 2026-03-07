---
name: install-linked-agent-skills
description: Use when a user pastes a GitHub repo URL, `skills.sh` link, `owner/repo@skill` reference, or local git path for an external skill package and wants it imported into `~/.dotfiles/.config/agent-hub/skills/vendor` with `Codex` and `Claude Code` entrypoints rebuilt automatically.
---

# Install Linked Agent Skills

## Overview

When a user gives you a link to an external skill package, do not leave it floating in chat and do not install it into tool-owned directories directly.

Import the package into:

- `~/.dotfiles/.config/agent-hub/skills/vendor/<package>`

Then regenerate entrypoints:

- `~/.agents/skills`
- `~/.claude/skills`

## When to Use

Use this skill when:

- the user pastes a GitHub link for a skill package
- the user pastes a `skills.sh` link
- the user gives an `owner/repo@skill` reference
- the user gives a local git path and wants to import it into the shared skill library

Do not use this skill for:

- skills you are authoring yourself from scratch
- project-local `AGENTS.md` or `CLAUDE.md`
- runtime caches or tool internals

## Core Rule

For external skill links:

1. import into `~/.dotfiles/.config/agent-hub/skills/vendor/`
2. keep the upstream package boundary intact
3. rebuild entrypoints with `bootstrap.sh`
4. verify with `check.sh`

## Installation Command

Use the bundled installer script instead of hand-writing `git submodule` commands:

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/install-linked-agent-skills/scripts/install-linked-skill.sh "<link>" [vendor-name]
```

Examples:

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/install-linked-agent-skills/scripts/install-linked-skill.sh \
  "https://github.com/obra/superpowers"

bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/install-linked-agent-skills/scripts/install-linked-skill.sh \
  "https://skills.sh/vercel-labs/agent-skills/vercel-react-best-practices"

bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/install-linked-agent-skills/scripts/install-linked-skill.sh \
  "owner/repo@skill-name" custom-package-name
```

## Workflow

### 1. Normalize the link

Accept any of these inputs:

- `https://github.com/<owner>/<repo>`
- `git@github.com:<owner>/<repo>.git`
- `https://skills.sh/<owner>/<repo>/<skill>`
- `<owner>/<repo>@<skill>`
- local git path

If the link points to a skill inside a larger package, import the package into `vendor/` and let the entrypoint builder expose the concrete skills.

### 2. Run the installer script

The script will:

- derive the upstream repo URL
- choose the vendor directory name
- add the package under `~/.dotfiles/.config/agent-hub/skills/vendor/`
- run `bootstrap.sh --force`
- run `check.sh`

### 3. Report the result

After installation, report:

- the installed vendor directory
- whether it was newly imported or already present
- which `Codex` and `Claude Code` entrypoints were refreshed

## Common Mistakes

- cloning a linked skill somewhere outside `agent-hub`
- copying files manually instead of preserving an upstream package boundary
- editing `~/.agents/skills` or `~/.claude/skills` directly
- forgetting to rebuild entrypoints after import
- treating a link to one skill as a reason to scatter files into personal directories

## Completion Checklist

Before calling the import done:

1. the package exists under `~/.dotfiles/.config/agent-hub/skills/vendor/`
2. `bash ~/.dotfiles/.config/agent-hub/scripts/bootstrap.sh --force` has run
3. `bash ~/.dotfiles/.config/agent-hub/scripts/check.sh` passes
4. the resulting symlink destinations are reported back to the user
