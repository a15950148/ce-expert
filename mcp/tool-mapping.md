---
mcp_bridge_repo: https://github.com/miscusi-peek/cheatengine-mcp-bridge
mcp_server_name: cheatengine
verified_bridge_version: v12.0.0
verified_ref: unknown
verified_date: 2026-08-03
verified_env: Windows 11 x64 / Cheat Engine MCP Bridge v12.0.0
compatibility: Verified
decay_type: methodology
recheck_trigger: Bridge 升版、工具改名、参数或返回结构变更
note: >-
  现象到工具的映射关系。工具名依赖 Bridge，映射逻辑本身与版本无关。
---

# 工具映射说明 (Tool Mapping) & 工具选择决策树

> 对应适配要求 4（工具选择决策树）与最终交付物「工具映射说明」。
> 把**用户现象 / 人工 CE 操作**映射到**真实 MCP 工具**与**原 workflow 文件**，作为 AI 选工具的速查。

## 1. 工具选择决策树

```
用户目标 / 现象
│
├─ 已知精确值（金币 = 15000）
│   └─► Memory Scan
│         scan_all → next_scan(收敛) → get_scan_results → read_integer 验证
│
├─ 未知值（血条忽高忽低）
│   └─► Unknown Value Scan
│         scan_all 建候选集 → next_scan(increased/decreased/changed/unchanged) 迭代 → 收敛
│         （复杂用 persistent_scan_* 会话）
│
├─ 重启后地址变了
│   └─► Pointer Analysis
│         pointer_rescan → read_pointer_chain 验证 → validate_pointer_chains → 固化指针
│
├─ 想知道「谁改写了这个值」
│   └─► Find What Writes / Accesses
│         find_references(addr)  [或隐形] start_dbvm_watch(addr,"w")
│         → get_breakpoint_hits / stop_dbvm_watch → disassemble(命中地址)
│
├─ 需要稳定、可开关的修改
│   └─► AOB Scan + Auto Assemble
│         aob_scan_module_unique(pattern,"game.exe")
│         → generate_code_injection_script(addr) → 补 Enable/Disable/恢复
│         → auto_assemble_check → auto_assemble
│
├─ 字符串 / 资源类
│   └─► search_string / read_string
│
├─ 对象 / 结构 / 类
│   └─► Structure & Engine
│         dissect_structure / get_rtti_classname / create_structure
│         （按引擎选路径见 mcp/engine-analysis.md）
│
├─ 批量固化交付
│   └─► Cheat Table
│         create_memory_record → save_table
│
└─ 想直接执行高级 Lua
    └─► evaluate_lua（兜底，非首选）
```

**难度提示**：扫描类（Memory/Unknown Scan）= 入门；指针/调试/结构 = 进阶；AOB 注入/Lua 训练器 = 高阶。详见 `SKILL.md` 的 Task Router 难度列。

## 2. 人工 Workflow ↔ MCP 工具 ↔ 原 workflow 文件

| 原 workflow | 人工操作 | 对应 MCP 工具 |
|---|---|---|
| `workflows/01-modify-known-value.md` | 值扫描 | `scan_all`, `next_scan`, `get_scan_results`, `read_integer` |
| `workflows/02-find-unknown-value.md` | 未知值扫描 | `scan_all` + `next_scan(changed/increased/decreased/unchanged)`；`persistent_scan_*` |
| `workflows/03-find-dynamic-address.md` | 动态地址 | `pointer_rescan`, `read_pointer_chain` |
| `workflows/04-pointer-scan.md` | 指针扫描 | `pointer_rescan`, `validate_pointer_chains` |
| `workflows/05-create-stable-address.md` | 稳定地址 | `read_pointer_chain` + `register_symbol` + `auto_assemble`(指针脚本) |
| `workflows/06-find-accessing-code.md` | 找访问代码 | `find_references`, `start_dbvm_watch` |
| `workflows/07-find-writing-code.md` | 找写入代码 | `find_references`(写), `set_data_breakpoint`, `stop_dbvm_watch` |
| `workflows/08-trace-back-to-base.md` | 回溯基类 | `find_call_references`, `read_pointer_chain` |
| `workflows/09-analyze-data-structure.md` | 结构分析 | `dissect_structure`, `create_structure`, `add_element_to_structure` |
| `workflows/10-identify-player-object.md` | 玩家对象 | `get_rtti_classname`, `read_pointer_chain`（引擎相关见 `engine-analysis.md`） |
| `workflows/11-handle-shared-code.md` | 共享代码 | `find_references` + 寄存器/实例过滤（`analyze_pointer_access`） |
| `workflows/12-create-aob-injection.md` | AOB 注入 | `aob_scan_module_unique`, `generate_code_injection_script`, `assemble_instruction`, `auto_assemble` |
| `workflows/13-create-toggle-script.md` | 开关脚本 | `auto_assemble`(Enable/Disable) |
| `workflows/14-create-cheat-table.md` | CT 表 | `create_memory_record`, `set_memory_record_value`, `save_table` |
| `workflows/15-build-lua-trainer.md` | Lua 训练器 | `evaluate_lua` + `templates/lua-toggle.lua` |

## 3. 诊断现象 ↔ MCP 工具 ↔ 原 diagnostics 文件

| 现象 | 优先工具 | 参考 |
|---|---|---|
| 搜不到值 | `read_integer`(试类型), `read_memory`, `search_string`, `pause_process` | `diagnostics/01`, `02` |
| 地址重启失效 | `pointer_rescan`, `validate_pointer_chains`, `enum_modules` | `diagnostics/03` |
| 指针失效 | `validate_pointer_chains`, 重新 `pointer_rescan` | `diagnostics/04` |
| 断点不触发 | `set_data_breakpoint`, `start_dbvm_watch`(隐形) | `diagnostics/05` |
| 注入崩溃 | `auto_assemble_check`, `copy_memory`(原字节), `set_memory_protection` | `diagnostics/07` |
| 共享代码误伤 | `find_references` + 实例过滤 | `diagnostics/08`, `workflows/11` |
| 版本更新失效 | `aob_scan_module_unique`, 重新 `pointer_rescan`, 引擎重定位 | `diagnostics/10`, `engine-analysis.md` |
| 找不到/受保护 | `get_process_list`, `open_process`, 权限核查 | `diagnostics/10` |

## 4. 模块职责速记

```
Skill（知识/推理/决策/Workflow）  ──选择并调用──►  MCP Bridge（工具/读写/调试/返回）
            ↑ 解析返回决定下一步                         ↓ 内存读写/调试执行
            └──────────────── 数据回传 ───────────────►  Cheat Engine → Target
```

- **不要**把 cheatengine-mcp-bridge 仓库中 `mcp_cheatengine.py` / ce_mcp_bridge.lua 的实现写进 Skill。
- **不要**修改 `cheatengine-mcp-bridge` 仓库。
- Skill 只描述「用什么工具、传什么、怎么解读」——本目录（`mcp/`）即适配层。

## 5. 相关文档索引

- `mcp/architecture.md` — 后端架构与模块化边界
- `mcp/mcp-tools.md` — 全部真实工具（名称/参数/返回/场景），权威来源
- `mcp/ai-workflow.md` — AI 驱动的 6 步分析流程
- `mcp/result-parsing.md` — 如何解读各类返回
- `mcp/trainer-dev.md` — 修改器开发（CT/AA/Lua/AOB，含四要素）
- `mcp/engine-analysis.md` — Unity Mono / IL2CPP / Unreal
- `mcp/troubleshooting.md` — 故障排查
