**English** | [中文](README.zh-CN.md)

# skm

**Agent Skill Manager** — a repository for managing, diagnosing, organizing, syncing, and upgrading skills used by `Codex` and `Claude Code`.

`skm` is not an app-runtime replacement, and it is not a domain-specific coding skill pack.
Its job is more foundational: it keeps your local agent-skill setup understandable, repairable, and maintainable over time.

If you already use `Codex` or `Claude Code` and want `~/.skm` to be the source of truth for your local skills, this repository is for you.

## What This README Assumes

This README assumes:

- you already have `Codex` or `Claude Code` installed
- you want `~/.skm` to be the source of truth for local agent skills
- you want the agent to help inspect, initialize, organize, and sync your setup

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

## Next Step

If you already have `Codex` or `Claude Code`, the best next step is to paste the universal prompt above into your agent.
If you want to understand planned future improvements, see `ROADMAP.md`.
