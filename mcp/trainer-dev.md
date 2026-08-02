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
  四要素（enable/disable/还原/错误处理）为通用规范，与 Bridge 版本无关。
---

# 修改器开发流程 (Trainer Development)

> 生成可交付的修改器产物，并映射到对应 MCP 工具。对应适配要求 6。
> **硬性规则**：任何写入/注入类代码必须包含 ① Enable 逻辑 ② Disable 逻辑 ③ 原始代码恢复 ④ 错误处理。

## 0. 落地用 MCP 工具速查

| 产物 | 主要工具 |
|---|---|
| Cheat Table (.CT) | `create_memory_record` / `set_memory_record_value` / `save_table` / `load_table` |
| Auto Assemble 脚本 | `auto_assemble` / `auto_assemble_check` / `generate_code_injection_script` |
| CE Lua 脚本 | `evaluate_lua` |
| AOB 注入 | `aob_scan_module_unique` / `assemble_instruction` / `copy_memory`（存原字节）/ `auto_assemble` |

> 现成模板见 `templates/aa-aob-injection.txt`、`templates/aa-basic-injection.txt`、`templates/aa-enable-disable.txt`、`templates/lua-toggle.lua`。

## 1. Cheat Table (.CT)

**流程**
1. 确认地址（静态或指针链）。
2. `create_memory_record(description, address, var_type)` 添加记录；指针地址用 `base+offsets` 形式传入。
3. 多记录后用 `save_table(filename)` 固化；需要时可 `load_table(filename, merge=true)` 合并。
4. 复杂表里可 `create_structure` 固化对象结构，记录引用该结构。

**原则**
- 指针记录勾选指针（用 `base+offsets`），保证重启可用。
- 遵循 `references/13-cheat-table-design.md` 的命名/分组规范。

## 2. Auto Assembler 脚本（通用可逆框架）

标准结构（Enable 启用修改，Disable 恢复原始）：

```asm
[ENABLE]
// 1) 备份原始字节（用 copy_memory 先取到 original_bytes，再在此 db 恢复）
// 2) 分配新内存并写入补丁
alloc(newmem, 2048)
label(returnhere)
label(originalcode)

newmem:
  // 你的修改逻辑（如强制血量 = 9999）
  originalcode:
    // 原始指令（必须保留，保证游戏正常）
    jmp returnhere

INJECT:
  jmp newmem
  nop  // 若被覆盖的原始指令是多字节，用 nop 补齐

returnhere:

[DISABLE]
INJECT:
  db 8B 45 00   // ← 原始字节（从 copy_memory 取得），恢复现场
dealloc(newmem)
```

**错误处理 / 验证**
- 落地前必调 `auto_assemble_check(script, enable=true)` 确认 `valid:true`，否则不 `auto_assemble`。
- `aobscanmodule` 失败（pattern 不唯一）时，先 `aob_scan_module_unique` 确认唯一性再写脚本。
- 启用后用 `read_integer` 复核效果；`enable→disable→enable` 三次 + 重启验证（见 `mcp/ai-workflow.md` 闭环标准）。

## 3. AOB Injection（完整模板 + 四要素）

```asm
[ENABLE]
// —— 定位锚点（要求唯一）——
aobscanmodule(INJECT, game.exe, 48 89 5C 24 08 55 56 57 48 83 EC 20)

alloc(newmem, 1024)
label(returnhere)
label(originalcode)

newmem:
  // Enable 逻辑：在此插入你的补丁（如 nop 掉扣血 / 强制返回值）
  originalcode:
    // 原始指令（必须与 INJECT 处被覆盖的指令一致）
    jmp returnhere

INJECT:
  jmp newmem
returnhere:

[DISABLE]
INJECT:
  db 48 89 5C 24 08   // 原始代码恢复（来自 copy_memory 的 original_bytes）
dealloc(newmem)
```

四要素检查清单：
- ✅ **Enable 逻辑**：`newmem` 中的补丁。
- ✅ **Disable 逻辑**：`[DISABLE]` 段把 `INJECT` 处恢复为原始字节。
- ✅ **原始代码恢复**：`db <original_bytes>` + `dealloc`，与 Enable 对称。
- ✅ **错误处理**：`auto_assemble_check` 不通过不执行；pattern 不唯一先用 `aob_scan_module_unique` 校验；`alloc` 失败时回退到 `allocate_memory` 并 `set_memory_protection` 为 rwx。

## 4. CE Lua 脚本

用于训练器 UI / 热键 / 定时器（进阶）。结构示例：

```lua
if syntaxcheck then return end   -- 语法检查时跳过执行
local ok, err = pcall(function()
  -- 训练器逻辑：创建表单、绑定热键、读写地址
  -- 参考 references/12-lua-api.md 与 workflows/15-build-lua-trainer.md
end)
if not ok then
  print("Lua trainer error: " .. tostring(err))   -- 错误处理
end
```

- 落地：`evaluate_lua(code)`。
- 错误用 `pcall` 包裹，避免整段失败无提示。
- 热键/开关模板见 `templates/lua-toggle.lua`。

## 5. 注入前必做（防崩）

1. `copy_memory(INJECT, N)` 保存被覆盖的原始字节 → 用于 `[DISABLE]` 的 `db`。
2. `get_memory_protection(INJECT)` 确认可写；不可写则 `set_memory_protection` / `full_access`。
3. `auto_assemble_check` 语法校验。
4. 先小范围启用，观察是否崩溃；崩溃见 `mcp/troubleshooting.md`（注入崩溃）。

## 6. 交付与版本

- 把以上产物统一 `save_table` 为一个 `.CT`，或随附 `.ct` + 说明。
- 游戏更新导致偏移/pattern 失效 → 见 `mcp/troubleshooting.md`（版本更新失效）与 `mcp/engine-analysis.md`（按引擎重新定位）。
- 所有交付必须可 Disable 还原，且默认仅本地单机授权使用。
