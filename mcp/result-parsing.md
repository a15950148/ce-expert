---
mcp_bridge_repo: https://github.com/miscusi-peek/cheatengine-mcp-bridge
mcp_server_name: cheatengine
verified_bridge_version: v12.0.0
verified_commit: unknown
verified_date: 2026-08-03
verified_env: Windows 11 x64 / Cheat Engine MCP Bridge v12.0.0
compatibility: Partial
decay_type: bridge-implementation
recheck_trigger: Bridge 升版、工具改名、参数或返回结构变更
note: >-
  返回结构（success/error 字段）由 Bridge 决定，改动会静默破坏解析假设。
---

# MCP 返回结果解析

> AI 如何理解 MCP 工具返回的数据并决定下一步。对应适配要求 5。
> 所有返回几乎都是 JSON 字符串，根含 `success`。**先判 `success`，失败再读错误信息。**

## 1. 通用解析原则

- **`success: false`**：停止当前路径，读 `error`/`message`，转入排查（见 `mcp/troubleshooting.md`）。
- **分页字段**（`offset`/`limit`/`total`/`returned`）：结果多时分批拉，循环直到 `returned < limit`。
- **地址字段**：字符串形式；做指针运算时转整数，输出时转回十六进制字符串。用 `register_symbol` 给稳定地址命名，避免后续硬编码散落。
- **模块基址**：`enum_modules` 返回的 `base` 每次启动可能变化，指针链务必用「模块名+偏移」或 `register_symbol` 表达，不要写死绝对地址。

## 2. 各类结果解析

### 2.1 内存地址（read_integer / read_memory）
- `read_integer` → `value`（数值）、`hex`（十六进制）。验证：再读一次是否一致（排除瞬态）。
- `read_memory` → `bytes`（int 数组）、`data`（hex 字符串）。用于结构/DUMP；可用 `checksum_memory` 做指纹比对。
- **下一步**：单值修改→`auto_assemble`/`create_memory_record`；结构→`dissect_structure`。

### 2.2 指针链（read_pointer_chain / validate_pointer_chains）
- `read_pointer_chain` 的 `chain` 数组逐步回显：
  - `step`：第几跳；`address`：该跳解析出的地址；`pointer_value`：该地址存的值（指向下一跳）；`hex_offset`：本跳偏移（如 `+0x3C`）；`description`：基址/说明。
  - `final_address`/`final_value`：链末端地址与读出的值。
- **验证方法**：用 `read_integer(final_address)` 确认 `final_value` 等于预期；若不等，说明某跳失效（重启/版本变化）。
- `validate_pointer_chains` 的 `matches` 才是**真正有效**的链；`unreadable` 表示中途不可读；用 `matches` 生成稳定指针。
- **下一步**：取 `matches[0]` 的 `base+offsets` → 写指针型 CT 记录或 AA 脚本。

### 2.3 汇编指令（disassemble / get_instruction_info）
- `instructions:[{address, bytes, instruction, size}]`。重点识别：
  - **写入访问**：`mov [reg+off], src`、`add [reg+off], imm` → 这是「改值的代码」。
  - **读取访问**：`mov dst, [reg+off]` → 消费该值的代码。
  - **基址+偏移**：从中提取 `offset`，配合 `analyze_pointer_access` 判断结构体字段。
  - **call**：`analyze_function`/`find_call_references` 展开调用关系。
- **下一步**：在写入指令处设 `set_data_breakpoint` 或 `start_dbvm_watch` 抓上下文；或用 `aob_scan_module_unique` 锚定该函数做注入。

### 2.4 AOB 扫描结果（aob_scan / aob_scan_module* / generate_signature）
- `addresses:[{address, value}]`；`count` 为命中数。
- **选择策略**：
  - `count == 1` 或用了 `_unique` → 直接作注入锚点。
  - `count > 1` → 缩小 pattern（加更多字节/上下文）或改用 `aob_scan_module` 限定模块；仍多则用 `find_references` 定位调用点。
- `generate_signature(address)` → 自动生成唯一签名，省去手工构造 pattern。
- **下一步**：用 `assemble_instruction` 构造新指令字节，配合 `generate_code_injection_script` 做注入。

### 2.5 对象结构（dissect_structure / get_structure_elements / get_rtti_classname）
- `dissect_structure` → CE 推测的字段布局；`get_structure_elements` → `[{name, offset, type}]`。
- `get_rtti_classname(address)` → C++ 类名（UE/原生 C++ 识别对象类型）。
- **下一步**：`create_structure`+`add_element_to_structure` 固化；跨进程复用（尤其 IL2CPP，见 `mcp/engine-analysis.md`）。

### 2.6 断点命中（get_breakpoint_hits / stop_dbvm_watch）
- `hits:[{id, address, timestamp, breakpoint_type, registers?, stack?}]`；`registers` 含触发时的 CPU 上下文（RAX/RBX/...）。
- **解析要点**：`instruction_address`（来自 `find_references` 的 `references[].address` 或 `stop_dbvm_watch` 的 `hits[].instruction_address`）即写入代码位置；`registers` 可确认写入的值来源。
- **下一步**：`disassemble(instruction_address)` 看上下文 → `aob_scan_module_unique` 锚定 → 注入。

## 3. 结果 → 下一步 决策表

| 解析结论 | 下一步动作 | 工具 |
|---|---|---|
| `scan_all` count 仍大 | 改变数值再 `next_scan` | `next_scan` |
| 候选收敛到 1 | 验证并固化 | `read_integer` → `create_memory_record`/`auto_assemble` |
| 地址重启失效 | 做指针扫描/验证 | `pointer_rescan`/`validate_pointer_chains` |
| 找到写入指令 | 锚定函数做注入 | `aob_scan_module_unique` → `generate_code_injection_script` |
| `aob_scan` count>1 | 加长 pattern / 限定模块 | `aob_scan_module_unique` |
| 断点命中写入代码 | 看上下文确定 patch 点 | `disassemble` → `assemble_instruction` |
| `validate_pointer_chains` matched≥1 | 取稳定链固化 | `register_symbol` + AA/CT |
| `dissect_structure` 给出字段 | 固化结构复用 | `create_structure`/`add_element_to_structure` |
| `success:false` | 转排查 | `mcp/troubleshooting.md` |

## 4. 常见误读坑

- 把**相对偏移**当**绝对地址**：指针链里的 `hex_offset` 是相对上一跳的，最终要算 `base + Σoffsets`。
- 忽略**分页**：`get_scan_results` 一次只回 `limit` 条，循环拉全。
- 把 `read_pointer` 的 `pointer`（指针值）和 `final_value`（指向的值）混淆。
- AOB `??` 用太多导致 `count` 巨大：逐步收紧 pattern 或用 `_module_unique`。
