---
mcp_bridge_repo: https://github.com/miscusi-peek/cheatengine-mcp-bridge
mcp_server_name: cheatengine
verified_bridge_version: v12.0.0
verified_ref: unknown
verified_date: 2026-08-03
verified_env: Windows 11 x64 / Cheat Engine MCP Bridge v12.0.0
compatibility: Verified
decay_type: bridge-implementation
recheck_trigger: Bridge 升版、工具改名、参数或返回结构变更
note: >-
  架构与连接方式随 Bridge 版本变化；server name 变更会导致全文件失效。
---

# MCP 后端架构 (Architecture)

> 本文件说明 AI Agent 如何通过 **Cheat Engine MCP Bridge** 调用 Cheat Engine。
> 对应适配要求 1（后端说明）与 9（模块化职责）。

## 1. 系统架构

```
AI Agent  (本 Skill：知识 / 推理 / 决策 / Workflow)
   │  MCP Protocol — JSON-RPC over stdio（或 TCP relay）
   ▼
Cheat Engine MCP Bridge  (Python FastMCP Server: mcp_cheatengine.py)
   │  Named Pipe: \\.\pipe\CE_MCP_Bridge_v99  (或 TCP relay 转发)
   ▼
Cheat Engine  (运行 ce_mcp_bridge.lua；DBVM 可选)
   │  进程内存访问 / 调试 / 扫描 / AA / Lua
   ▼
Target Process  (.exe / 游戏)
```

数据流向是**双向**的：AI 发出工具调用 → Bridge 转成 CE Lua 命令 → CE 执行并返回 JSON → Bridge 回传 AI。

## 2. 各层职责

| 层 | 职责 |
|---|---|
| **AI Agent / 本 Skill** | 理解用户目标、判断变量类型、选择合适的 MCP 工具、解析返回结果、决定下一步操作。**不直接调用 CE 内部 API，不写 MCP 实现代码。** |
| **Cheat Engine MCP Bridge** | MCP Server（FastMCP，server name = `cheatengine`），把 MCP 工具调用转成 CE Lua 命令，通过 Named Pipe 发给 CE，并把结果格式化为 JSON 字符串返回。 |
| **Cheat Engine** | 原生内存读写、调试器、内存扫描、结构分析、Auto Assemble、Lua 执行。 |
| **Target Process** | 被分析的本地程序 / 游戏。 |

## 3. 模块化边界（适配要求 9）

```
┌─────────────────────────────────────────────┐
│ Skill（知识层）                               │
│   知识 · 推理 · 决策 · Workflow               │
│   → 只描述「用什么工具 / 传什么 / 怎么解读」  │
└───────────────┬─────────────────────────────┘
                │ 选择并调用
                ▼
┌─────────────────────────────────────────────┐
│ Cheat Engine MCP Bridge（工具层）            │
│   工具调用 · 内存读写 · 调试执行 · 返回数据   │
│   → 不把其实现代码写入 Skill                  │
└─────────────────────────────────────────────┘
```

**禁止事项**
- 不要把 MCP Server 的 Python/Lua 实现代码写进 Skill 任何文件。
- 不要修改 `cheatengine-mcp-bridge` 仓库（它是独立后端）。
- Skill 内只允许出现「工具名 + 参数说明 + 返回解析 + 使用场景」形式的描述。

## 4. 连接与验证

1. 在 Cheat Engine 中通过 File → Execute Script 运行 ce_mcp_bridge.lua（位于 cheatengine-mcp-bridge 仓库的 MCP_Server/ 目录；或粘贴 dofile 调用并指定其路径）。成功提示：
   `[MCP v12.0.0] MCP Server Listening on: CE_MCP_Bridge_v99`
2. MCP 客户端配置（如 `mcp_config.json`）：
   ```json
   {
     "servers": {
       "cheatengine": {
         "command": "python",
         "args": ["C:/path/to/MCP_Server/mcp_cheatengine.py"]
       }
     }
   }
   ```
3. 调用 **`ping`** 验证连通性，期望返回：
   `{"success": true, "version": "12.0.0", "message": "CE MCP Bridge Active"}`

> 跨平台（非 Windows）用 TCP relay：Windows 端先跑 `python ce_tcp_relay.py --host 127.0.0.1 --port 9876`；另一端设环境变量 `CE_MCP_TRANSPORT=tcp`、`CE_MCP_HOST=127.0.0.1`、`CE_MCP_PORT=9876` 后启动 `mcp_cheatengine.py`。

## 5. 安全边界（继承并强化）

- 仅限**授权本地单机**分析；不绕过反作弊、不操纵联机服务。
- 遵守 CE MCP Bridge 的环境变量限制：`CE_MCP_ALLOW_SHELL` 默认禁用，`run_command` / `shell_execute` 默认返回 `PERMISSION_DENIED`。
- **必须禁用** CE 设置中的「Query memory region routines」，否则可能 BSOD。
- 管道（Named Pipe）模式仅 Windows（依赖 `pywin32`）；其他平台用 TCP relay。
- DBVM / DBK 内核功能需 CE 已加载 DBVM，调用前先确认环境支持。

## 6. 工具调用通用约定

- **Server name**：`cheatengine`（所有工具在其下）。
- **地址参数**：统一为字符串，支持十六进制 `"0x00400000"` 或符号 `"game.exe"+0x1234`（符号需先用 `get_symbol_address` / `register_symbol` 解析）。
- **偏移参数**：整数列表，如 `offsets=[0x10, 0x20, 0x8]`。
- **返回格式**：几乎都是 JSON 字符串，根含 `success` 字段。**务必先判断 `success`，失败再读错误信息**。
- **分页工具**（`get_scan_results`、`enum_modules`、`get_address_list` 等）用 `offset` / `limit` 翻页，避免一次拉取过多。

## 7. 相关文档

- `mcp/mcp-tools.md` — 全部真实工具的名称 / 参数 / 返回 / 场景
- `mcp/ai-workflow.md` — AI 驱动的端到端分析流程
- `mcp/tool-mapping.md` — 人工操作 ↔ MCP 工具 ↔ 原 workflow 映射 + 工具选择决策树
- `mcp/result-parsing.md` — 如何解读各类返回
- `mcp/trainer-dev.md` — 修改器开发（CT / AA / Lua / AOB）
- `mcp/engine-analysis.md` — Unity / Unreal 引擎分析
- `mcp/troubleshooting.md` — 故障排查
