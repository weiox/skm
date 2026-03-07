# skill-init

`skill-init` 是一组围绕 agent skills 生命周期的工作流技能包。

它解决的不是“某个领域怎么写代码”，而是：

- 如何发现合适的 skill
- 如何把外部 skill 包导入本地体系
- 如何把散乱的 skill 收敛到单一来源
- 如何让 `Codex` 和 `Claude Code` 的入口层保持一致

## 定位

把 `skill-init` 理解成：

- **skills about skills**
- **agent skill lifecycle toolkit**
- **agent-hub` 的技能初始化与维护能力包**

它的职责聚焦在这条链路：

**discover -> install -> organize -> verify -> sync -> update -> release**

## 仓库边界

这个仓库只放与 skill 本身管理有关的内容：

- skill 发现
- skill 导入
- skill 归档与整理
- skill 入口重建与校验
- 后续的升级、诊断、发布能力

这个仓库不负责：

- 项目级 `AGENTS.md` / `CLAUDE.md`
- 某个业务领域的编码 skill
- 运行时缓存、历史记录或工具内部状态

## 当前包含

- `doctor-agent-skills`
- `extract-agent-skill-pack`
- `find-skills`
- `install-linked-agent-skills`
- `organize-agent-skills`
- `release-agent-skill-pack`
- `sync-agent-skills`
- `update-vendor-skills`

## 与 `agent-hub` 的关系

- `skill-init` 是一个独立 skill 包仓库
- `agent-hub` 是本地的技能编排层与入口层
- `agent-hub` 通过 vendor 目录消费 `skill-init`
- `bootstrap.sh` / `check.sh` 负责把这个包暴露给 `Codex` 和 `Claude Code`

## 仓库结构

```text
skills/
├── doctor-agent-skills/
├── extract-agent-skill-pack/
├── find-skills/
├── install-linked-agent-skills/
├── organize-agent-skills/
├── release-agent-skill-pack/
├── sync-agent-skills/
└── update-vendor-skills/
```

## 下一步

已规划的优化方向见 `ROADMAP.md`。
