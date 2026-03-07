---
name: extract-agent-skill-pack
description: Use when a set of local skills should be split out from an existing source tree into a standalone skill-pack repository skeleton, while keeping the original skills in place until the new repository is reviewed and reconnected through `vendor`.
---

# Extract Agent Skill Pack

## Overview

This skill takes one or more existing local skills and extracts them into a standalone repository skeleton.

The first version is intentionally **copy-first**:

- it creates the new pack
- it does not delete the source skills
- it generates a checklist for the follow-up release and vendor reconnect steps

## When to Use

Use this skill when:

- a group of local skills has become coherent enough to deserve its own repo
- you want to split skills out of a larger local source tree
- you want a safer first step before publishing or reconnecting through `vendor`

Do not use this skill to import an external repo. Use `install-linked-agent-skills` for that.

## Core Rule

Extract first, delete later.

The safe sequence is:

1. copy selected skills into a new repo skeleton
2. review the new pack
3. run `release-agent-skill-pack`
4. reconnect the released repo through `vendor`
5. only then remove the original local copies

## Command

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skill-init/skills/extract-agent-skill-pack/scripts/extract-agent-skill-pack.sh \
  <source-root> <target-repo> <skill-name...>
```

Example:

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skill-init/skills/extract-agent-skill-pack/scripts/extract-agent-skill-pack.sh \
  ~/.dotfiles/.config/agent-hub/skills/personal/shared \
  ~/tmp/my-skill-pack \
  alpha-skill beta-skill
```

## What It Produces

The script creates:

- `README.md`
- `skills/<skill-name>/SKILL.md`
- `.git/`
- `EXTRACT-CHECKLIST.md`

## Common Mistakes

- moving source skills too early
- extracting unrelated skills into one pack
- forgetting to run `release-agent-skill-pack` before publishing
- forgetting to reconnect the new repo through `vendor`

## Completion Checklist

1. target repo skeleton exists
2. selected skills are copied into `skills/`
3. original source skills still exist
4. `EXTRACT-CHECKLIST.md` is generated
