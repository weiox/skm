# skm Roadmap

`skm` 的目标不是变成“各种 skill 的大仓库”，而是成为 **agent skills 生命周期工具包**。

核心主线：

**discover -> install -> organize -> verify -> sync -> update -> release**

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

当前已经扎实的基础：

- 核心架构清晰：`~/.skm`（source of truth）→ `exports/shared`（导出层）→ `~/.claude/skills` / `~/.agents/skills`（入口层）
- 生命周期主线已经成形：**discover -> install -> organize -> verify -> sync -> update -> release**
- 仓库内主要 lifecycle skills 已经有完整的 `SKILL.md` 文档，包含触发条件、工作流、常见错误与完成标准
- `bootstrap.sh` / `check.sh` 已经具备较好的参数化能力，适合 fake-home 测试和跨机器复用
- 双语 README、最佳实践与通用提示词已经能说明 `skm` 的职责边界

当前存在但还不完整的部分：

- `skm-create-custom-agent-skill` 已有设计与文档，但仍缺少配套实现脚本
- `skm-organize-agent-skills` 已有设计与文档，但自动化不足，很多步骤仍依赖人工执行
- 测试覆盖仍偏窄，尚未系统覆盖 `bootstrap`、`sync`、`install`、`update` 等核心流程
- 脚本虽然使用了 `set -euo pipefail`，但错误提示的上下文与恢复建议还不够友好

当前仍然缺失的能力：

- personal / vendor 之间的同名 skill 冲突检测与优先级规则
- `SKILL.md` 的 schema / lint 校验与命名规范检查
- 卸载 / 清理工作流与配套脚本
- `skm` 自身版本化与 vendor pinning 机制
- CI/CD、自动化测试与 submodule 漂移检测
- Windows / WSL 的验证与回退方案
- skill 依赖声明与依赖图
- `CONTRIBUTING.md` 与外部协作指南

---

## Roadmap

下面的 roadmap 重点不再重复已经存在的架构与文档，而是聚焦下一阶段的优化方向：**补齐核心 -> 强化可靠性 -> 进入生态化**。

## Phase 0: Keep the Boundaries Sharp

目标：继续守住 `skm` 的边界，让 source-of-truth 模型保持清晰而不过度扩张。

### P0-1. 持续收敛职责边界

- 持续明确 `~/.skm`、`exports/shared`、`~/.agents/skills`、`~/.claude/skills` 的职责
- 继续避免把 dotfiles 管理、运行时缓存、项目级规范混进 `skm`

### P0-2. 保持 skill 模板一致

- 所有 `SKILL.md` 继续统一采用触发条件、核心规则、工作流、常见错误、完成检查等结构
- 从“靠文档约定”逐步过渡到“靠 lint 自动检查”

### P0-3. 保持脚本参数化

- 继续以 `SKM_DIR`、`CLAUDE_SKILLS_DIR`、`CODEX_SKILLS_DIR` 等环境变量为准
- 为 fake-home 测试、跨机器复用和未来跨平台支持打基础

---

## Phase 1: Fill the Missing Core

目标：补齐当前“文档完整、实现不完整”以及“核心能力缺口明显”的部分。

### P1-1. 实现 `skm-create-custom-agent-skill`

职责：

- 生成标准 skill 目录与 `SKILL.md`
- 补齐脚手架、校验、导出与验证步骤
- 让“创建 skill”从手工编辑变成标准 workflow

### P1-2. 补强 `skm-organize-agent-skills` 自动化

职责：

- 自动盘点散落的 skill 目录
- 给出归类建议、迁移计划与风险提示
- 尽量减少依赖人工判断和手工搬运

### P1-3. 增加 skill 冲突检测

职责：

- 检测 `personal/` 与 `vendor/` 的同名 skill
- 定义明确的优先级与冲突提示
- 在 `doctor` / `sync` 过程中提前暴露结构问题

### P1-4. 增加 `SKILL.md` lint / schema 校验

职责：

- 检查 frontmatter 必填字段，如 `name`、`description`
- 检查命名规范、目录命名与触发描述质量
- 让 skill 质量控制从人工 review 走向自动化

### P1-5. 扩大测试覆盖

职责：

- 为 `bootstrap`、`sync`、`install`、`update` 增加 fake-home 测试
- 标准化 fake home / fake vendor repo / fake dotfiles 测试夹具
- 让核心工作流具备可重复验证能力

### P1-6. 改善错误提示与恢复建议

职责：

- 为关键脚本补充更有上下文的失败信息
- 在失败时明确下一步恢复动作
- 降低用户面对 shell 错误时的理解成本

---

## Phase 2: Operational Reliability

目标：把 `skm` 从“功能可用”提升到“长期运维友好”。

### P2-1. 增加卸载 / 清理工作流

职责：

- 提供文档化的移除流程
- 增加解除入口链接和清理生成层的脚本
- 明确“移除入口”与“删除 source of truth”之间的区别

### P2-2. 引入版本锁定与 vendor pinning

职责：

- 让 `skm` 自身具备更清晰的版本语义
- 让 vendor 子模块优先追踪 tag 而不是漂移的 branch
- 支持类似 `update --pin` 的受控升级路径

### P2-3. 建立 CI/CD

职责：

- 用 GitHub Actions 跑 lint、测试与 smoke checks
- 检查 submodule 漂移与基础脚本可执行性
- 把“仓库健康”从本地经验变成持续验证

### P2-4. 补齐 dotfiles 集成指南

职责：

- 说明 `personal/` 是否进入 dotfiles
- 说明 `vendor/` 的缓存、重装与 `.gitignore` 策略
- 让多机初始化与重装路径更清楚

---

## Phase 3: Portability and Ecosystem

目标：让 `skm` 能跨平台、跨机器、跨 skill 生态稳定工作。

### P3-1. 增加 Windows / WSL 支持与回退方案

职责：

- 明确 bash-only 脚本在 WSL / Windows 上的支持边界
- 增加 symlink 不可用时的降级策略
- 让跨平台使用不再依赖隐性前提

### P3-2. 增加 skill 依赖声明与依赖图

职责：

- 允许一个 skill 声明依赖另一个 skill
- 在安装或校验时解析前置依赖
- 为更复杂的 skill pack 打基础

### P3-3. 与 `skills.sh` 深度集成

职责：

- 在 `skm` 中直接提供 search / import 体验
- 减少“先在外部查找，再手工接入”的摩擦
- 逐步靠近统一的 skill 发现与导入入口

### P3-4. 增加多机同步与可复现状态

职责：

- 结合 dotfiles、git remote 或 manifest 记录本机 skill 状态
- 让一台机器的 `skm` 状态可以在另一台机器重建
- 把“本地经验”沉淀成“可复制配置”

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

`skm` 关心的是技能生命周期，而不是囤积更多 skill。

---

## Candidate Skills

建议优先顺序：

1. `skm-lint-agent-skills`
2. `skm-uninstall-agent-skills`
3. `adopt-agent-skill-pack`

---

## Decision Rule

如果以后想往 `skm` 里再加一个新 skill，先问：

**它是不是在解决 skill 的发现、导入、整理、校验、升级或发布问题？**

- 如果是：考虑加入
- 如果不是：放到别的 skill 包里
