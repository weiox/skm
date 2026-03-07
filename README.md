**English** | [中文](README.zh-CN.md)

# skm

**Agent Skill Manager** — keep `Codex` and `Claude Code` skills in one managed source tree, so they stay inspectable, repairable, and easy to evolve.

`skm` is not an app-runtime replacement, and it is not a domain-specific coding skill pack.
Its job is more foundational: it keeps your local agent-skill setup understandable, repairable, and maintainable over time.

If you already use `Codex` or `Claude Code` and want `~/.skm` to be the source of truth for your local skills, this repository is for you.

## Who This Is For

`skm` is a good fit if:

- you already have `Codex` or `Claude Code` installed
- you want `~/.skm` to be the source of truth for local agent skills
- you want agent-guided diagnosis, initialization, organization, sync, and updates

## Who This Is Not For

`skm` is probably not what you need if:

- you are looking for a replacement for the agent runtime itself
- you want project-local instructions such as `AGENTS.md` or `CLAUDE.md`
- you want domain-specific coding skills rather than skill-library management
- you have not installed `Codex` or `Claude Code` yet

If you do not have an agent installed yet, install `Codex` or `Claude Code` first, then come back to `skm`.

## Get Started in 3 Minutes

Recommended flow:

1. Put this repository at `~/.skm`
2. Make sure your agent can read local skills on your machine
3. Paste the following universal prompt into `Codex` or `Claude Code`

### Universal Prompt for Codex and Claude Code

```text
Please treat ~/.skm as the single source of truth for my local agent skills and help me run an initialization check.

Requirements:
1. Start with skm-doctor-agent-skills to inspect ~/.agents/skills and ~/.claude/skills, and classify entries as OK, BROKEN, or UNMANAGED.
2. If skills are scattered, duplicated, or the directory responsibilities are unclear, use skm-organize-agent-skills to explain how the layout should be cleaned up.
3. If ~/.skm itself looks trustworthy, continue with skm-sync-agent-skills to rebuild and sync the Codex and Claude Code entrypoint layers.
4. If external skill packages are missing, tell me whether I should use skm-install-linked-agent-skills.
5. If vendor packages look stale, tell me whether I should use skm-update-vendor-skills.
6. When finished, summarize in English: current health, what you inspected or repaired, what still needs my confirmation, and the recommended next step.

Before doing anything that deletes, replaces, or overwrites existing entrypoint links, tell me first.
```

## What This Prompt Triggers

In a healthy flow, the agent will usually work in this order:

1. run `skm-doctor-agent-skills` to inspect the current entrypoint layers
2. use `skm-organize-agent-skills` if the layout itself is messy
3. use `skm-sync-agent-skills` if `~/.skm` is already a trustworthy declared state
4. recommend `skm-install-linked-agent-skills` if a vendor package is missing
5. recommend `skm-update-vendor-skills` if installed vendor packages are stale

The outcome should be a practical summary of:

- whether the current setup is healthy
- which links are `OK`, `BROKEN`, or `UNMANAGED`
- what the agent actually repaired
- what still needs your confirmation
- whether you should organize, install, sync, or update next

## What Pain Points skm Solves

Most people do not realize they need `skm` when they first install a skill. They realize it later, when the setup starts drifting and nobody remembers what is actually being managed.

The pain usually looks like this:

- **Problem: external skills get installed wherever they happen to fit**
  - Consequence: people clone or copy skills directly into `~/.agents/skills` or `~/.claude/skills`, which works briefly but makes updates, auditing, and migration harder later.
  - How `skm` helps: it gives external packs a stable home in `vendor/` and rebuilds entrypoints from a managed source tree instead of treating tool-owned directories as the place to maintain content.

- **Problem: local skills slowly scatter across multiple directories**
  - Consequence: after enough experiments, old machines, and one-off edits, nobody can confidently say which copy is the real source of truth.
  - How `skm` helps: it centers the declared layout under `~/.skm` and treats visible agent directories as generated entrypoints rather than editable source directories.

- **Problem: one agent sees a skill and another does not**
  - Consequence: you end up debugging symptoms instead of structure, because broken symlinks, stale links, and unmanaged entrypoints all look like random visibility bugs.
  - How `skm` helps: it gives you a diagnosis-first workflow so you can classify entries as `OK`, `BROKEN`, or `UNMANAGED` before deciding whether to rebuild the runtime view.

- **Problem: vendor updates feel risky and manual**
  - Consequence: people either avoid updates, or they edit the wrong place by hand and make the setup harder to reproduce.
  - How `skm` helps: it turns vendor updates into a managed sequence of update, rebuild, and verification instead of ad hoc filesystem surgery.

- **Problem: useful personal skills have no clear path to become reusable packs**
  - Consequence: local skills stay trapped as private experiments, or extracting them later becomes messy because there was never a clean packaging boundary.
  - How `skm` helps: it gives you a path from local skills to extractable and releasable skill packs without abandoning the local source-of-truth model.

## If You Already Have Many Skills

This is one of the most common reasons to use `skm`: you already have local skills, but they may be scattered across places like:

- `~/.agents/skills`
- `~/.claude/skills`
- `~/.codex/skills`
- old directories, temporary folders, or personal scratch paths

Do not start by cleaning them manually. A better workflow is:

1. diagnose the current state first
2. separate what belongs in `personal`
3. separate what belongs in `vendor`
4. decide whether the entrypoint layers should then be synced

You can say this to your agent:

```text
Please treat ~/.skm as the only source of truth. First inspect ~/.agents/skills, ~/.claude/skills, and ~/.skm; diagnose the current state before changing anything; then tell me which skills should live in personal, which should live in vendor, and which old entrypoints can be removed. After I confirm, help me sync the entrypoint layers.
```

## What skm Helps Solve

`skm` manages the **agent-skill lifecycle**, especially this path:

**discover -> install -> organize -> verify -> sync -> update -> release**

It is especially useful when:

- you found an external skill repository and do not know where it should live
- your local skills are scattered across several entrypoint directories
- `Claude Code` sees a skill but `Codex` does not, or the reverse
- vendor skill packs are outdated and you want a safe update path
- you wrote local skills and want to extract or publish them as a separate pack

## Common Workflows

### 1. I want to inspect and initialize my current setup

Use:

- `skm-doctor-agent-skills`
- `skm-organize-agent-skills`
- `skm-sync-agent-skills`

This is the best starting point when your machine already has skill-related state but you do not fully trust it yet.

### 2. I found an external skill link and want to import it safely

Use:

- `skm-find-skills`
- `skm-install-linked-agent-skills`

The principle is simple: external skill packs belong in `vendor/`, not directly inside `~/.agents/skills` or `~/.claude/skills`.

### 3. My skill directories are a mess and I want one source of truth

Use:

- `skm-doctor-agent-skills`
- `skm-organize-agent-skills`
- `skm-sync-agent-skills`

The principle is: diagnose first, organize second, sync last.

### 4. My vendor packages are outdated

Use:

- `skm-update-vendor-skills`

This flow updates the selected vendor packages, rebuilds entrypoints, and verifies the result.

### 5. I wrote a local skill pack and want to split or release it

Use:

- `skm-extract-agent-skill-pack`
- `skm-release-agent-skill-pack`

The usual flow is: extract first, validate release readiness second, then decide whether it should come back through `vendor/`.

## Included Skills

- `skm-doctor-agent-skills` — diagnose `Codex` and `Claude Code` entrypoints as `OK`, `BROKEN`, or `UNMANAGED`
- `skm-extract-agent-skill-pack` — extract a set of local skills into a standalone repository skeleton
- `skm-find-skills` — discover external installable skills
- `skm-install-linked-agent-skills` — import an external skill pack into `vendor/`
- `skm-organize-agent-skills` — consolidate scattered local skills into a clean source-of-truth layout
- `skm-release-agent-skill-pack` — validate a standalone skill pack before release
- `skm-sync-agent-skills` — rebuild runtime entrypoints from the declared `skm` layout
- `skm-update-vendor-skills` — update vendor skill packs and rebuild entrypoints

## Directory and Runtime Model

The recommended runtime model is:

- `~/.skm` keeps the real sources of your skills
- `~/.skm/exports/shared` is the shared exported view
- `~/.claude/skills` and `~/.agents/skills` point to that shared exported view

The goal is to separate:

- source content
- exported view
- tool-owned entrypoint directories

That separation reduces drift, duplicate links, and hard-to-debug visibility problems.

### Directory Responsibilities

- `skills/` — built-in `skm` skills
- `personal/` — your own local personal skills
- `vendor/` — third-party skill packs such as `superpowers`
- `exports/shared/` — the exported view shared by `Claude Code` and `Codex`

### One Important Rule

- `personal/` is for local private skills on the current machine
- do not treat `~/.agents/skills` or `~/.claude/skills` as source directories
- if a personal skill should become shareable or public, extract it into a real pack and reconnect it through `vendor/`

If you keep `skm` inside your dotfiles, treat dotfiles as the installation layer, not as the true content model for reusable skills.

### Why is my new skill still missing?

The most common confusion is creating a skill under `~/.skm/personal` and expecting the current `Codex` session to see it immediately.

- Step 1: rebuild the runtime entrypoints with `skm-sync-agent-skills` or `bash ~/.skm/scripts/bootstrap.sh --force`
- Step 2: verify with `bash ~/.skm/scripts/check.sh`
- Step 3: start a new `Codex` session

Why this happens:

- `Codex` runtime discovery comes from `~/.agents/skills`, not from `~/.skm/personal` directly
- in this layout, `~/.agents/skills` points to `~/.skm/exports/shared`
- `Codex` discovers skills at session startup, so an already-running session will not hot-reload a newly exported skill

## What skm Does Not Manage

`skm` does not manage:

- project-local instruction files such as `AGENTS.md` or `CLAUDE.md`
- domain-specific coding skills for application work
- chat history, runtime caches, or tool-internal state
- installing the agent runtime itself

## Repository Structure

```text
skills/
├── skm-doctor-agent-skills/
├── skm-extract-agent-skill-pack/
├── skm-find-skills/
├── skm-install-linked-agent-skills/
├── skm-organize-agent-skills/
├── skm-release-agent-skill-pack/
├── skm-sync-agent-skills/
└── skm-update-vendor-skills/
```

## Usage Examples

### Import an external skill pack

When you find a skill pack on GitHub or skills.sh that you want to use, just paste the link to your agent:

```text
Please import https://github.com/anthropics/skill-example into my skm setup.
```

The agent will recognize the link and trigger `skm-install-linked-agent-skills` automatically. It will clone the package into `vendor/`, rebuild entrypoints, and verify the result.

Accepted formats:

- GitHub URL: `https://github.com/anthropics/skill-example`
- Shorthand: `anthropics/skill-example@my-skill`
- skills.sh link: `https://skills.sh/anthropics/skill-example/my-skill`
- Local git path: `~/projects/my-skill-pack`

### Discover skills from the public ecosystem

If you do not have a specific link but want to find something useful, just describe what you need:

```text
Is there a skill for code review?
```

```text
Find a skill that can help with changelog generation.
```

The agent will trigger `skm-find-skills`, search the public skills.sh ecosystem, present matching results, and offer to install them into your `vendor/`.

### Just say `skm` + what you want

You only need to remember one word: `skm`.

`skm` covers the full agent-skill lifecycle — **discover, install, organize, verify, sync, update, release**. As long as your request falls within this range, just say `skm` and describe what you need. The agent will match your intent to the right skill automatically.

| Lifecycle stage | Example prompt |
|---|---|
| **discover** | `skm` — is there a skill for generating changelogs? |
| **install** | `skm` — import `https://github.com/anthropics/skill-example` |
| **organize** | `skm` — my skills are scattered everywhere, help me clean up |
| **verify** | `skm` — my Codex skills seem broken, check what is wrong |
| **sync** | `skm` — I just added a new personal skill, rebuild entrypoints |
| **update** | `skm` — check if vendor packages have upstream changes |
| **release** | `skm` — check if my skill pack is ready to publish |

You do not need to remember exact skill names like `skm-doctor-agent-skills` or `skm-sync-agent-skills`. The word `skm` plus your intent is enough — the agent resolves the rest.

## Best Practices

### 1. Never edit entrypoint directories directly

`~/.agents/skills` and `~/.claude/skills` are generated output, not source directories. If you edit files there, your changes will be overwritten the next time `skm-sync-agent-skills` runs.

Always edit under `~/.skm/personal/` or `~/.skm/vendor/`, then sync.

### 2. Diagnose before fixing

When something breaks, resist the urge to delete and recreate links manually. Run `skm-doctor-agent-skills` first. The diagnosis tells you exactly what is `OK`, `BROKEN`, or `UNMANAGED`, so you fix only what needs fixing.

### 3. One source of truth, two entrypoint layers

The core model is:

```
~/.skm (source of truth)
  └── exports/shared (generated view)
       ├── ~/.claude/skills → symlink
       └── ~/.agents/skills → symlink
```

Both `Claude Code` and `Codex` read from the same exported view. If one agent sees a skill and the other does not, the problem is almost always in the entrypoint layer — not in the skill itself.

### 4. Keep vendor and personal separate

- `vendor/` is for third-party skill packs imported via `skm-install-linked-agent-skills`. Do not manually edit files inside `vendor/`.
- `personal/` is for your own local skills. If a personal skill matures and you want to share it, use `skm-extract-agent-skill-pack` to split it into its own repository.

### 5. Sync after every change

After creating a new skill in `personal/`, importing a new vendor pack, or updating an existing pack, always rebuild the entrypoint layer:

```text
Please run skm sync to rebuild my entrypoints.
```

Then start a **new** agent session. Running sessions do not hot-reload newly exported skills.

### 6. Use the universal prompt for initial setup

The universal prompt in the "Get Started" section is designed to run the full diagnostic-organize-sync cycle in order. It is the safest way to bootstrap a fresh machine or recover from a messy state.

### 7. Treat dotfiles as the installation layer

If you version `~/.skm` inside your dotfiles repository, keep in mind:

- dotfiles are the **installation and integration** layer
- `personal/` skills are machine-local and may not belong in a shared dotfiles repo
- `vendor/` packages are reproducible via `skm-install-linked-agent-skills`, so you can `.gitignore` them and reinstall on each machine

## Next Step

If you already have `Codex` or `Claude Code`, the best next step is to paste the universal prompt above into your agent.
If you want to understand planned future improvements, see `ROADMAP.md`.
