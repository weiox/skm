# skm

**Agent Skill Manager** — discover, install, link, and upgrade skills for Claude Code & Codex.

`skm` 不是教你“某个领域怎么写代码”的 skill 包。  
它专门解决另一类更基础、也更容易变乱的问题：

- 看到一个 skill 仓库，不知道该装到哪里
- 本地 skill 散落在 `~/.agents/skills`、`~/.claude/skills`、个人目录里
- `Claude Code` 能识别，`Codex` 却不识别，或者反过来
- vendor skill 包已经落后，但不知道如何安全更新
- 本地写出来的一组 skill 想拆成独立仓库，却没有标准流程

如果你已经遇到过上面这些情况，那 `skm` 就是为你准备的。

## 用户痛点

### 痛点 1：外部 skill 很容易“装上就乱”

典型场景：

- 你在 GitHub 或 `skills.sh` 上看到一个 skill
- 第一反应是直接 clone 到 `~/.claude/skills/` 或 `~/.agents/skills/`
- 一开始能用，但过一阵子就忘了它到底从哪里来的、怎么更新、怎么迁移到新电脑

`skm` 的做法是：

- 外部 skill 包统一进入 `vendor/`
- `Codex` 和 `Claude Code` 的入口层只放生成出来的 symlink
- 源码、入口、升级路径三者分离

### 痛点 2：本地 skill 会越来越散

典型场景：

- 你自己写了几个 skill
- 一部分放在 `personal/`
- 一部分放在旧目录
- 一部分已经被复制进 agent 的入口目录里
- 过一段时间之后，你已经说不清哪个才是真正的 source of truth

`skm` 的做法是：

- 明确 `agent-hub/skills` 才是技能源目录
- 用 `organize` 和 `sync` 把运行态重新拉回声明态

### 痛点 3：入口层经常坏，但很难查

典型场景：

- 某个 skill 昨天还能用，今天突然没了
- `~/.agents/skills` 里有一堆旧链接
- 你不知道到底是 broken link、unmanaged link，还是路径已经改过

`skm` 的做法是：

- 先用 `skm-doctor-agent-skills` 做结构诊断
- 再用 `skm-sync-agent-skills` 清理和重建

### 痛点 4：自己写的 skill 想发布，但没有标准动作

典型场景：

- 你在本地写了一组 skill
- 想把它们独立成一个 GitHub 仓库
- 但不知道应该先抽出来、先发版、还是先接回 vendor

`skm` 的做法是：

- 先 `extract`
- 再 `release`
- 最后再接回 `vendor`

## skm 的职责

`skm` 关心的是 **agent skills 生命周期**，主线是：

**discover -> install -> organize -> verify -> sync -> update -> release**

它不负责：

- 项目级 `AGENTS.md` / `CLAUDE.md`
- 某个业务领域的编码 skill
- 聊天历史、缓存、工具内部状态

## 典型使用场景

### 场景 1：我刚看到一个新 skill 链接，想安全纳入本地体系

你可以这样做：

1. 用 `skm-find-skills` 先确认是否合适
2. 用 `skm-install-linked-agent-skills` 导入到 `vendor/`
3. 自动重建 `Codex` / `Claude Code` 的入口层

示例：

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/skm-install-linked-agent-skills/scripts/skm-install-linked-skill.sh \
  "https://github.com/owner/repo"
```

适合的 skill：

- `skm-find-skills`
- `skm-install-linked-agent-skills`

### 场景 2：我的 skill 目录已经很乱，想重新收敛

你可以这样做：

1. 用 `skm-doctor-agent-skills` 看当前有哪些坏链和非托管链接
2. 用 `skm-organize-agent-skills` 明确应该如何收敛
3. 用 `skm-sync-agent-skills` 把运行态重建到正确状态

示例：

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/skm-doctor-agent-skills/scripts/skm-doctor-agent-skills.sh

bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/skm-sync-agent-skills/scripts/skm-sync-agent-skills.sh
```

适合的 skill：

- `skm-doctor-agent-skills`
- `skm-organize-agent-skills`
- `skm-sync-agent-skills`

### 场景 3：vendor 里的 skill 包已经落后了

你可以这样做：

1. 用 `skm-update-vendor-skills` 更新单个包或全部包
2. 更新后自动跑 `bootstrap.sh --force`
3. 再自动跑 `check.sh`

示例：

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/skm-update-vendor-skills/scripts/skm-update-vendor-skills.sh

bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/skm-update-vendor-skills/scripts/skm-update-vendor-skills.sh superpowers
```

适合的 skill：

- `skm-update-vendor-skills`

### 场景 4：我本地写了一组 skill，想拆成独立仓库

你可以这样做：

1. 用 `skm-extract-agent-skill-pack` 先生成一个独立仓库骨架
2. 用 `skm-release-agent-skill-pack` 做发布前检查并生成 checklist
3. 后续再接回 `vendor/`

示例：

```bash
bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/skm-extract-agent-skill-pack/scripts/skm-extract-agent-skill-pack.sh \
  ~/.dotfiles/.config/agent-hub/skills/personal \
  ~/tmp/my-skill-pack \
  alpha-skill beta-skill

bash ~/.dotfiles/.config/agent-hub/skills/vendor/skm/skills/skm-release-agent-skill-pack/scripts/skm-release-agent-skill-pack.sh \
  ~/tmp/my-skill-pack
```

适合的 skill：

- `skm-extract-agent-skill-pack`
- `skm-release-agent-skill-pack`

## 当前包含的 skills

- `skm-doctor-agent-skills`：检查入口层是否 broken / unmanaged
- `skm-extract-agent-skill-pack`：把一组本地 skill 提取成独立仓库骨架
- `skm-find-skills`：发现外部可安装 skill
- `skm-install-linked-agent-skills`：把外部 skill 导入 `vendor/`
- `skm-organize-agent-skills`：整理本地散乱 skill 的结构
- `skm-release-agent-skill-pack`：发布前校验独立 skill 包
- `skm-sync-agent-skills`：把运行态入口同步回声明态
- `skm-update-vendor-skills`：更新 vendor skill 包并重建入口

## 与 agent-hub 的关系

你可以把两者理解成：

- `skm`：技能生命周期能力包
- `agent-hub`：本地技能编排层和入口层

也就是说：

- `skm` 提供“怎么发现、安装、整理、验证、同步、更新、发布”
- `agent-hub` 负责“这些技能在本机上怎么挂载、怎么暴露给 agent”

## 仓库结构

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

## 下一步

如果你想继续了解后续优化方向，见 `ROADMAP.md`。
