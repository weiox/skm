# skill-init Roadmap

`skill-init` 的目标不是变成“各种 skill 的大仓库”，而是成为 **agent skills 生命周期工具包**。

核心主线：

**discover -> install -> organize -> verify -> update -> release**

---

## North Star

让一个用户从“我看到一个 skill 链接”到“这个 skill 被安全纳入本地体系并在 `Codex` / `Claude Code` 中可用”，变成稳定、可验证、可迁移的流程。

成功状态：

- 本地 skill 只有一个真实来源
- 外部 skill 包有明确 vendor 边界
- 入口层始终可重建
- 每一步都可验证，而不是靠人工记忆

---

## Scope

### In Scope

- 发现可安装的 skill
- 导入外部 skill 包
- 整理本地散乱 skill
- 检查入口层与真实来源是否一致
- 更新 vendor skill 包
- 把一组 skill 抽成独立仓库并重新接回

### Out of Scope

- 业务领域 skill 本身
- 项目仓库内的团队规范
- 聊天历史、缓存、工具内部元数据
- 通用 dotfiles 管理

---

## Current State

当前已完成：

- `doctor-agent-skills`
- `find-skills`
- `install-linked-agent-skills`
- `organize-agent-skills`

当前短板：

- 仓库级 README 仍偏简略
- 安装脚本仍偏向 `agent-hub` 目录结构
- 与 `agent-hub` 的职责边界需要进一步清晰
- 测试还主要依赖上层 `agent-hub`

---

## Roadmap

## Phase 0: Clarify the Package

目标：把 `skill-init` 从“能用”提升到“边界清晰”。

### P0-1. 固化仓库定位

- 在 README 中明确 `skill-init` 是 skills lifecycle toolkit
- 明确它与 `agent-hub` 的关系
- 明确仓库的 in-scope / out-of-scope

### P0-2. 统一 skill 模板

让仓库内所有 skill 保持统一结构：

- When to Use
- Core Rule
- Workflow
- Common Mistakes
- Completion Checklist

### P0-3. 参数化脚本

把脚本里的关键路径逐步参数化：

- `AGENT_HUB_ROOT`
- `DOTFILES_ROOT`
- `CLAUDE_SKILLS_DIR`
- `CODEX_SKILLS_DIR`

结果：

- `skill-init` 不再只适用于单一机器布局
- 更适合作为独立仓库公开复用

---

## Phase 1: Complete the Lifecycle

目标：补齐目前缺失的技能运维动作。

### P1-1. `doctor-agent-skills`

职责：

- 检查坏链
- 检查重复 skill
- 检查入口污染
- 检查 vendor / personal 边界错误

价值：

- 让排查问题变成标准流程

### P1-2. `update-vendor-skills`

职责：

- 更新 vendor skill 包
- 检查 submodule 漂移
- 在更新后重建入口并校验

价值：

- 把 vendor 升级从“手工操作”变成标准 workflow

### P1-3. `sync-agent-skills`

职责：

- 对齐 `agent-hub` 与两边入口目录
- 清理旧链接
- 保证当前运行态与声明态一致

价值：

- 减少本地目录结构腐化

---

## Phase 2: Publishing Workflows

目标：让 skill 从“本地资产”演进成“可发布资产”。

### P2-1. `extract-agent-skill-pack`

职责：

- 从现有本地 skill 中抽取一组
- 生成独立仓库结构
- 帮助用户把其接回 `vendor`

价值：

- 复用你刚完成的 `skill-init` 拆仓经验

### P2-2. `release-agent-skill-pack`

职责：

- 准备 README
- 检查目录结构
- 检查 frontmatter
- 生成首发检查清单

价值：

- 降低从“本地可用”到“公开可用”的摩擦

### P2-3. `adopt-agent-skill-pack`

职责：

- 接管一个已有外部仓库
- 纳入 `vendor`
- 补入口层和验证逻辑

价值：

- 让别人发布的 skill 包也能进入同一体系

---

## Phase 3: Testing and Reliability

目标：让 `skill-init` 仓库自己具备独立验证能力。

### P3-1. 仓库内测试迁移

把与 `skill-init` 强相关的测试逐步迁到仓库内部：

- 安装流程测试
- vendor 接入测试
- 链接重建测试

### P3-2. 测试夹具标准化

建立 fake home / fake dotfiles / fake vendor repo 的统一测试夹具。

### P3-3. 发布前验证入口

增加一个标准命令，例如：

```bash
./scripts/verify.sh
```

覆盖：

- 文档结构
- 关键脚本可执行
- 主要工作流 smoke test

---

## Design Principles

### 1. One Source of Truth

不要让 skill 源码散落在工具入口目录里。

### 2. Preserve Package Boundaries

外部 skill 包尽量保持完整，不手工拆散复制。

### 3. Entrypoints Are Generated

`~/.agents/skills` 和 `~/.claude/skills` 是生成层，不是维护层。

### 4. Verification Before Claims

所有整理、导入、升级动作都应该有明确的验证步骤。

### 5. Lifecycle Over Collection

`skill-init` 关心的是技能生命周期，而不是囤积更多 skill。

---

## Candidate Skills

建议优先顺序：

1. `update-vendor-skills`
2. `sync-agent-skills`
3. `extract-agent-skill-pack`
4. `release-agent-skill-pack`

---

## Decision Rule

如果以后想往 `skill-init` 里再加一个新 skill，先问：

**它是不是在解决 skill 的发现、导入、整理、校验、升级或发布问题？**

- 如果是：考虑加入
- 如果不是：放到别的 skill 包里
