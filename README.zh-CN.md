[English](README.md) | **中文**

# skm

**Agent Skill Manager** —— 用来管理、诊断、整理、同步和升级 `Codex` / `Claude Code` 的 skills。

`skm` 不是业务开发 skill 包，也不是 agent 运行时。  
它解决的是另一类更基础的问题：你的本机 agent skills 应该放在哪里、怎么保持干净、怎么安全导入外部 skill、怎么修复坏掉的入口层、以及怎么长期维护这一整套本地 skills 体系。

如果你已经在使用 `Codex` 或 `Claude Code`，并且希望把 `~/.skm` 作为本机 skills 的 source of truth，`skm` 就是为你准备的。

## 这份 README 假设什么

这份 README 默认你是下面这种读者：

- 你已经安装了 `Codex` 或 `Claude Code`
- 你想把 `~/.skm` 作为本机 agent skills 的唯一 source of truth
- 你希望 agent 直接帮你做检查、初始化、整理和同步

如果你还没有安装 agent，请先安装 `Codex` 或 `Claude Code`，再回来使用 `skm`。

## 3 分钟开始使用

推荐顺序：

1. 把这个仓库放在 `~/.skm`
2. 确认你的 agent 可以读取本机 skills
3. 在 `Codex` 或 `Claude Code` 里粘贴下面这段通用提示词

### 给 Codex 和 Claude Code 的通用提示词

```text
请把 ~/.skm 视为我本机 agent skills 的唯一 source of truth，并帮我做一次初始化检查。

要求：
1. 先使用 skm-doctor-agent-skills 检查 ~/.agents/skills 和 ~/.claude/skills 的当前状态，区分 OK / BROKEN / UNMANAGED。
2. 如果发现 skills 散落、重复、或者目录职责不清，再结合 skm-organize-agent-skills 给我整理建议。
3. 如果 ~/.skm 本身结构可信，就继续使用 skm-sync-agent-skills 重建并同步 Codex 与 Claude Code 的入口层。
4. 如果发现缺失的外部 skill 包，再告诉我是否应该使用 skm-install-linked-agent-skills。
5. 如果发现 vendor 已经过时，再告诉我是否应该使用 skm-update-vendor-skills。
6. 完成后请用中文汇报：当前健康状态、你执行了哪些检查或修复、哪些地方还需要我确认，以及建议的下一步。

在执行会删除、替换或覆盖现有入口链接的操作前，先明确告诉我。
```

## 这段提示词会触发什么

正常情况下，agent 会按这样的顺序工作：

1. 用 `skm-doctor-agent-skills` 先诊断当前入口层
2. 如果结构混乱，再结合 `skm-organize-agent-skills` 解释应该怎样收敛
3. 如果 `~/.skm` 已经是可信声明态，就用 `skm-sync-agent-skills` 重建运行态入口
4. 如果你缺少外部 skill 包，再建议使用 `skm-install-linked-agent-skills`
5. 如果 vendor 包过旧，再建议使用 `skm-update-vendor-skills`

你最终应该得到一份清楚的结果说明：

- 当前是否健康
- 哪些入口是 `OK`、`BROKEN`、`UNMANAGED`
- agent 实际做了哪些修复
- 哪些地方还需要你确认
- 下一步该继续整理、安装、同步还是更新

## 如果你已经有一堆 skills

这是 `skm` 最常见的使用场景之一：你已经有一些本地 skills，但它们可能散落在：

- `~/.agents/skills`
- `~/.claude/skills`
- `~/.codex/skills`
- 旧目录、临时目录、个人目录

这时不要先手工清理。更好的做法是让 agent：

1. 先诊断当前状态
2. 区分哪些应该归入 `personal`
3. 区分哪些应该归入 `vendor`
4. 再决定是否同步入口层

你可以直接对 agent 说：

```text
请把 ~/.skm 作为唯一 source of truth，先盘点 ~/.agents/skills、~/.claude/skills 和 ~/.skm 的当前状态；优先做诊断，再告诉我哪些应该归入 personal、哪些应该归入 vendor、哪些是可以删除的旧入口；等我确认后，再帮我同步入口层。
```

## skm 能帮你解决什么

`skm` 主要处理的是 **agent skills 生命周期**，主线是：

**discover -> install -> organize -> verify -> sync -> update -> release**

它尤其适合下面这些问题：

- 看到一个外部 skill 仓库，不知道该装到哪里
- 本地 skill 散落在多个入口目录里，已经说不清 source of truth
- `Claude Code` 能识别，`Codex` 却不识别，或者反过来
- vendor skill 包已经落后，但不知道如何安全更新
- 你写了一组本地 skill，想拆成独立仓库并发布

## 常见任务入口

### 1. 我想先体检并初始化当前环境

优先使用：

- `skm-doctor-agent-skills`
- `skm-organize-agent-skills`
- `skm-sync-agent-skills`

适合你当前机器已经有 skill 痕迹，但状态未必健康的时候。

### 2. 我刚看到一个外部 skill 链接，想安全纳入本地体系

优先使用：

- `skm-find-skills`
- `skm-install-linked-agent-skills`

原则很简单：外部 skill 包进入 `vendor/`，不要直接把内容散落到 `~/.agents/skills` 或 `~/.claude/skills`。

### 3. 我的 skill 目录已经很乱，想重新收敛

优先使用：

- `skm-doctor-agent-skills`
- `skm-organize-agent-skills`
- `skm-sync-agent-skills`

原则是：先诊断，再整理，最后同步。

### 4. vendor 里的 skill 包已经落后了

优先使用：

- `skm-update-vendor-skills`

这个流程会更新指定的 vendor 包、重建入口层，并检查最终状态。

### 5. 我本地写了一组 skill，想拆成独立仓库或发布

优先使用：

- `skm-extract-agent-skill-pack`
- `skm-release-agent-skill-pack`

通常流程是：先抽取，再做发布前检查，最后再决定是否通过 `vendor/` 接回本体系。

## 当前包含的 skills

- `skm-doctor-agent-skills`：检查 `Codex` / `Claude Code` 的入口层是否为 `OK`、`BROKEN`、`UNMANAGED`
- `skm-extract-agent-skill-pack`：把一组本地 skill 提取成独立仓库骨架
- `skm-find-skills`：发现外部可安装 skill
- `skm-install-linked-agent-skills`：把外部 skill 包导入 `vendor/`
- `skm-organize-agent-skills`：整理本地散乱 skill 的结构
- `skm-release-agent-skill-pack`：发布前校验独立 skill 包
- `skm-sync-agent-skills`：把运行态入口同步回声明态
- `skm-update-vendor-skills`：更新 vendor skill 包并重建入口

## 目录与运行时模型

推荐的本地运行时模型是：

- `~/.skm` 维护 skills 的真实来源
- `~/.skm/exports/shared` 作为统一导出层
- `~/.claude/skills` 和 `~/.agents/skills` 指向这个共享导出层

这样做的目标，是把下面三层拆开：

- 源内容
- 导出视图
- agent 官方入口目录

这样更不容易出现入口层漂移、重复链接、或“表面还能用但已经不好维护”的问题。

### 仓库目录职责

- `skills/`：`skm` 自带的内建 skills
- `personal/`：你自己的本地 personal skills
- `vendor/`：外部 skill 包，例如 `superpowers`
- `exports/shared/`：给 `Claude Code` 和 `Codex` 共用的导出视图

### 一个重要约定

- `personal/` 只用于当前机器上的本地私有 skills
- 不要把 `~/.agents/skills` 或 `~/.claude/skills` 当成真实源码目录
- 如果某个 personal skill 未来要公开或跨机器共享，应该先抽成独立 skill 包，再通过 `vendor/` 接回

如果你在 `dotfiles` 中使用 `skm`，推荐把 `dotfiles` 视为安装与集成层，而不是可复用 skill 的真实内容模型。

## skm 不负责什么

`skm` 不负责：

- 项目级 `AGENTS.md` / `CLAUDE.md`
- 某个业务领域的编码 skill
- 聊天历史、缓存、工具内部状态
- agent 本体的安装与运行时

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

如果你已经安装好 `Codex` 或 `Claude Code`，最好的下一步就是把上面的通用提示词直接发给 agent。  
如果你想继续了解后续优化方向，见 `ROADMAP.md`。
