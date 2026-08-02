---
name: ce-expert
description: "授权本地、单机、教育及个人用途的 Cheat Engine 分析专家。覆盖数值查找（金币/血量/弹药/经验/未知值）、动态地址、多级指针、调试器断点、Auto Assembler、AOB 代码注入与 Cheat Table 设计。已适配 Cheat Engine MCP Bridge（FastMCP；server name cheatengine），AI 可通过 MCP 工具调用 CE 完成内存扫描、指针分析、调试、AOB 扫描、代码注入与修改器开发。当用户进行 CE 内存扫描、指针扫描、代码定位、AOB 注入、Lua 训练器或单机离线修改器分析时启用。英文关键词：Cheat Engine, memory scan, pointer scan, AOB injection, Auto Assembler, Lua trainer, Cheat Table, MCP Bridge。"
license: 教育及个人授权本地使用。仅限授权本地单机分析，不涉及绕过反作弊或联机服务操纵。
agent_created: true
allowed-tools: Read, Write, Edit, Grep, Glob
disable: false
---

# CE Expert Skill（Cheat Engine 分析专家）

## Purpose（目的）
为授权的离线、单机、教育及个人用途 Cheat Engine 分析提供结构化协助。本 skill 覆盖：数值发现、动态地址、指针、调试器分析、数据结构、Auto Assembler、AOB 注入、Lua 与 Cheat Table 设计。

## Operating Principles（操作原则）
1. 选择工作流之前，先明确用户的具体目标。
2. 优先观察与验证，而非假设。
3. 区分显示值、存储值、派生值与服务器权威值。
4. 处理动态地址时，同时调查指针链与代码访问两条路径。
5. 做代码注入前，先检查寄存器上下文，再改动指令。
6. 在证明唯一之前，将共享指令视为多对象代码。
   **判定动作（注入前必做，不是态度而是检查）**：看运算的操作数形态 ——
   `sub [addr],1` / `dec` 用立即数 → 专用代码，可直接改；
   `sub reg,reg` 减数是**寄存器** → 扣多少由调用者传入，即通用函数，
   **禁止修改该函数本身**（会连敌人血量一起改掉），必须改为 hook 调用点，见 `workflows/11-handle-shared-code.md`。
   > 此条曾被违反两次仍未察觉：原则写在这里也不等于会被执行，需要的是上面这种可判定的动作。
7. 每个脚本必须包含启用、禁用、还原与验证步骤。
8. 在重启与重复使用测试通过前，不得声称方案稳定。

## Decision Tree（决策树：从现象选路）

```
你的状态？
├─ 还没开始 / 想学基础 ──────────────► QUICKSTART + references/01-ce-basics.md
├─ 知道要改什么，但没找到 / 没改成功
│     ├─ 已知数值搜不到 ─────────────► workflows/01 / 02（入门）
│     └─ 重启后地址失效 ─────────────► workflows/03→04→05（入门→进阶）
├─ 想做"稳定 / 永久"修改
│     ├─ 需要指针 ──────────────────► workflows/04 / 05（进阶）
│     ├─ 改写 / 读取代码 ───────────► workflows/06 / 07（进阶）
│     ├─ 多对象 / 玩家专属混淆 ─────► workflows/10 / 11（高阶）
│     └─ 注入 / AOB / 热键 ─────────► workflows/12 / 13（高阶）
├─ 想做训练器 / 表
│     ├─ Cheat Table ───────────────► workflows/14（进阶）
│     └─ Lua UI 训练器 ─────────────► workflows/15（高阶）
└─ 出现报错 / 异常 ────────────────► 见下方 Symptom Quick Lookup
      ├─ 扫不到 / 不收敛 / 地址失效 ─► diagnostics/01~03
      ├─ 指针 / 断点 / AOB 异常 ────► diagnostics/04~06
      ├─ 注入崩溃 / 启用失败 / 误伤 ► diagnostics/07~09
      └─ 改不动 / 被回滚 / 疑似服务器 ► diagnostics/10
```

> 难度：入门=纯扫描；进阶=调试器 / 指针 / 结构；高阶=代码注入与 Lua。任何脚本都需做 enable→disable→enable 与重启验证。

## MCP 适配模式（通过 Cheat Engine MCP Bridge 调用 CE）

本 Skill 已适配 **Cheat Engine MCP Bridge**（FastMCP，server name `cheatengine`）。AI Agent 通过该 MCP 后端把工具调用转成 CE 操作，无需手工点击 GUI。

**架构**：AI Agent（本 Skill：知识/推理/决策/Workflow）→ MCP Bridge（工具/读写/调试/返回）→ Cheat Engine → Target Process。完整说明见 `mcp/architecture.md`。

**MCP 工具选择决策树（精简版）**

```
目标/现象
├─ 已知值 ─────────► Memory Scan: scan_all → next_scan → read_integer
├─ 未知值 ─────────► Unknown Scan: scan_all + next_scan(increased/decreased/changed)
├─ 重启失效 ───────► Pointer: pointer_rescan → validate_pointer_chains
├─ 谁改写了值 ─────► Find writes: find_references / start_dbvm_watch → disassemble
├─ 稳定可开关修改 ─► AOB + AA: aob_scan_module_unique → auto_assemble
├─ 对象/结构 ─────► dissect_structure / get_rtti_classname（按引擎见 engine-analysis）
└─ 固化交付 ───────► Cheat Table: create_memory_record → save_table
```

完整决策树、工具映射与真实工具清单见 `mcp/tool-mapping.md` 与 `mcp/mcp-tools.md`。

**模块职责**：Skill 负责知识/推理/决策/Workflow；MCP 负责工具调用/内存读写/调试执行/返回数据。不把 MCP 实现代码写入 Skill，不修改 `cheatengine-mcp-bridge` 仓库。

## QUICKSTART（快速入门路由）

**新手第一次使用 CE？** 按以下顺序学习：
1. `references/01-ce-basics.md` - 了解 CE 基础概念
2. `workflows/01-modify-known-value.md` - 修改已知数值（金币/弹药）
3. `examples/01-money.md` - 金币修改实例
4. `references/03-value-types.md` - 理解数值类型

**遇到问题？** 直接跳到 [Symptom Quick Lookup](#symptom-quick-lookup)

## Common Mistakes（常见错误速查）

| 错误 | 后果 | 解决方案 |
|---|---|---|
| 扫描类型选错（Exact vs Fuzzy） | 找不到值或结果不收敛 | 见 `references/04-scan-types.md` |
| 数值类型不匹配（整数 vs 浮点） | 扫描失败 | 见 `references/03-value-types.md` |
| 忘记验证 AOB 唯一性 | 注入错误地址，游戏崩溃 | 见 `workflows/12-create-aob-injection.md` |
| 注入后未重放原指令 | 游戏逻辑缺失，崩溃 | 见 `templates/aa-aob-injection.txt` |
| 硬编码绝对地址 | 重启后失效 | 见 `workflows/03-find-dynamic-address.md` |
| 未过滤共享代码 | 影响所有对象（敌人也无敌） | 见 `workflows/11-handle-shared-code.md` |
| 忘记测试 enable→disable→enable | 脚本不稳定 | 见 `diagnostics/07-injection-crashes-game.md` |

## Task Router（任务路由）

| 用户场景 | 优先加载 | 难度 |
|---|---|---|
| CE 基础概念/新手入门 | `references/01-ce-basics.md` | 参考 |
| 内存/进程/模块/指针模型 | `references/02-memory-and-process.md` | 参考 |
| 已知数值（如金钱） | `workflows/01-modify-known-value.md` | 入门 |
| 未知的血量/进度数值 | `workflows/02-find-unknown-value.md` | 入门 |
| 重启后地址变化 | `workflows/03-find-dynamic-address.md` | 入门 |
| 需要指针 | `workflows/04-pointer-scan.md` | 进阶 |
| 需要稳定方案 | `workflows/05-create-stable-address.md` | 进阶 |
| 需要找到读取某值的代码 | `workflows/06-find-accessing-code.md` | 进阶 |
| 需要找到改写某值的代码 | `workflows/07-find-writing-code.md` | 进阶 |
| 需要回溯对象/基类 | `workflows/08-trace-back-to-base.md` | 进阶 |
| 需要分析数据结构/还原对象字段布局 | `workflows/09-analyze-data-structure.md` | 进阶 |
| 需要玩家专属逻辑 | `workflows/10-identify-player-object.md` | 高阶 |
| 同一条代码影响玩家与敌人 | `workflows/11-handle-shared-code.md` | 高阶 |
| 需要注入脚本 | `workflows/12-create-aob-injection.md` | 高阶 |
| 需要开关/热键 | `workflows/13-create-toggle-script.md` | 进阶 |
| 需要 CT 表 | `workflows/14-create-cheat-table.md` | 进阶 |
| 需要 Lua UI/训练器 | `workflows/15-build-lua-trainer.md` | 高阶 |
| 需要 Lua API 参考（定时器/热键/表单/内存） | `references/12-lua-api.md` | 参考 |
| 需要 CT 表设计规范 | `references/13-cheat-table-design.md` | 参考 |
| Mono/Unity 等托管游戏 | `references/14-mono-and-managed-games.md` | 参考 |
| 改不动/找不到/服务器权威/防护限制 | `references/15-protection-and-limitations.md` | 参考 |
| 官方来源/学习资源/来源优先级 | `references/16-sources-and-references.md` | 参考 |
| 扫描/脚本/注入失败 | `diagnostics/` 中对应文件 | 排错 |
| MCP 后端架构 / 模块职责 / 连接验证 | `mcp/architecture.md` | 适配 |
| MCP 真实工具清单（名称/参数/返回/场景） | `mcp/mcp-tools.md` | 适配 |
| AI 驱动分析流程（6 步循环） | `mcp/ai-workflow.md` | 适配 |
| MCP 返回结果解析 | `mcp/result-parsing.md` | 适配 |
| 修改器开发（CT/AA/Lua/AOB，含四要素） | `mcp/trainer-dev.md` | 适配 |
| Unity Mono / IL2CPP / Unreal 引擎分析 | `mcp/engine-analysis.md` | 适配 |
| 故障排查（搜不到/失效/崩溃/版本更新） | `mcp/troubleshooting.md` | 适配 |
| 工具选择决策树 + 工具映射 | `mcp/tool-mapping.md` | 适配 |

## Examples & Templates Index（实例与模板索引）

**实例（examples/）— 按场景取用：**
| 实例 | 对应场景 / workflow |
|---|---|
| `examples/01-money.md` | 已知数值修改（workflow 01） |
| `examples/02-health.md` | 未知数值（workflow 02） |
| `examples/03-ammo.md` | 禁用写入 / 无限弹药（workflow 07） |
| `examples/04-experience.md` | 未知数值 / 经验（workflow 02） |
| `examples/05-multi-level-pointer.md` | 多级指针（workflow 04 / 05） |
| `examples/06-player-only-health.md` | 玩家专属（workflow 10） |
| `examples/07-damage-multiplier.md` | AOB 伤害倍率（workflow 12） |
| `examples/08-aob-injection.md` | AOB 注入（workflow 12） |
| `examples/09-shared-code-filter.md` | 共享代码过滤（workflow 11） |
| `examples/10-lua-trainer.md` | Lua 训练器（workflow 15） |

**模板（templates/）— 复制后改占位：**
| 模板 | 用途 |
|---|---|
| `templates/aa-aob-injection.txt` | AOB 代码注入骨架 |
| `templates/aa-basic-injection.txt` | 基础注入（改写 / 跳过） |
| `templates/aa-enable-disable.txt` | enable / disable 框架 |
| `templates/aa-register-filter.txt` | 寄存器 / 对象过滤 |
| `templates/cheat-table-layout.md` | CT 表布局规范 |
| `templates/lua-form.lua` | Lua 表单 UI |
| `templates/lua-hotkey.lua` | Lua 热键 |
| `templates/lua-toggle.lua` | Lua 开关 |

## Symptom Quick Lookup（症状速查 → diagnostics）
按现象直接定位排错文件，避免在场景表中逐条比对。

| 现象 | diagnostics 文件 |
|---|---|
| 扫不到任何地址 | `diagnostics/01-cannot-find-value.md` |
| 扫得到但候选不收敛 | `diagnostics/02-too-many-results.md` |
| 重启后地址失效 | `diagnostics/03-address-changes-after-restart.md` |
| 指针解析错误或间歇失效 | `diagnostics/04-pointer-does-not-work.md` |
| 断点 / Find what accesses(writes) 不命中 | `diagnostics/05-breakpoint-does-not-trigger.md` |
| `aobscan` 报找不到 | `diagnostics/06-aob-not-found.md` |
| 启用脚本即崩溃 / 触发动作时崩溃 | `diagnostics/07-injection-crashes-game.md` |
| 脚本启用报错、自动取消勾选 | `diagnostics/08-script-enable-failed.md` |
| 改值后敌人/NPC 也被影响 | `diagnostics/09-shared-code-affects-all-entities.md` |
| 改不动 / 被回滚 / 怀疑服务器或反作弊 | `diagnostics/10-server-side-or-protected-data.md` |

## Required Response Structure（要求的回复结构）
针对实际分析，回复应包含：
1. **当前结论** — 已知内容与仍不确定的部分。
2. **下一步操作** — 确切的 CE 动作或脚本步骤。
3. **预期观察** — 用户应看到的现象。
4. **决策分支** — 若结果与预期不符应如何处理。
5. **验证方式** — 如何确认正确性。

## Script Quality Rules（脚本质量规则）
- 保留原始指令，除非有意替换。
- 为注入代码分配足够内存。
- 使用唯一标签与清晰符号。
- 在依赖 AOB 前先验证其唯一性。
- 禁用时还原原始字节。
- 当存在稳定符号、指针或 AOB 时，避免硬编码绝对地址。
- 说明寄存器假设。
- x64 下注意 RIP 相对寻址与寄存器位宽。
- 测试 enable→disable→enable，并重启目标程序。

## Source Priority（来源优先级）
1. Cheat Engine 官方 Wiki、Help、Lua API、源码与论坛。
2. 成熟的逆向工程教育资源。
3. 社区教程仅作为补充示例。
4. 来源冲突时，优先采用官方/现行文档与直接观察。

详细来源清单、官方链接与冲突处理清单见 `references/16-sources-and-references.md`。

## Safety Boundary（安全边界）
聚焦授权本地分析。不提供用于绕过反作弊、突破访问控制或操纵在线多人服务的能力与指导。
