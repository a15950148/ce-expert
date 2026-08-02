# 故障排查模块 (Troubleshooting)

> 处理适配后常见失败。对应适配要求 8。每条都给出「现象 → 原因 → 用 MCP 工具排查 → 参考」。
> 通用前提：任何返回先判 `success:false`，读 `error`/`message` 再处理；不确定时先 `ping` 确认连接还在。

## 1. 搜索无结果（scan_all count = 0）

**可能原因**
- 值类型选错（把 float 当 dword，或整数实际是 qword）。
- `protection` 过滤掉了目标区域（默认可写不可执行 `+W-C`）。
- 数值在变化，扫描瞬间已不是你以为的值。
- 值以字符串/数组/定点数存储，而非普通整数。

**排查（MCP 工具）**
1. `read_integer(addr, type="float")` / `"double"` / `"qword"` 试探正确类型。
2. `read_memory(addr, 32)` dump 原始字节，人工判断编码方式。
3. `search_string(str)` 若值其实是字符串（如名称）。
4. 放宽扫描：确认目标模块可读（`enum_modules` 看基址/大小）。
5. `pause_process()` 冻结目标，避免扫描期间数值被改写造成误判。

**参考**：`diagnostics/01-cannot-find-value.md`、`diagnostics/02-too-many-results.md`。

## 2. 地址不稳定（重启后失效）

**可能原因**：目标地址是动态分配（堆/栈/每次 ASLR），不是模块基址+固定偏移。

**排查**
1. 转指针路线：`pointer_rescan(value)` 用旧扫描结果做指针重扫。
2. `read_pointer_chain(base, offsets)` 手动验证候选链是否指到正确值。
3. `validate_pointer_chains(chains, target)` 批量确认有效链（`matches` 才是真有效）。
4. 基址优先用**模块名+偏移**（`enum_modules` 拿 `game.exe` 基址）或 `register_symbol` 命名，避免写死绝对地址。
5. 把稳定链固化成指针型 CT 记录或 AA 脚本。

**参考**：`diagnostics/03-address-changes-after-restart.md`、`workflows/03-find-dynamic-address.md`、`workflows/04-pointer-scan.md`、`workflows/05-create-stable-address.md`。

## 3. 指针失效（链读出错误 / 不可读）

**可能原因**：基址变化（版本/ASLR）、中间节点失效、结构体布局改变、反作弊改了内存布局。

**排查**
1. `validate_pointer_chains` 重新验证，丢弃 `unreadable`/`misses`。
2. 重新 `pointer_rescan` 生成新链。
3. 检查 `base`：若是绝对地址每次变，改用模块基址+偏移或符号。
4. 若怀疑布局变化 → 见「5. 版本更新失效」与 `mcp/engine-analysis.md` 重新定位。

**参考**：`diagnostics/04-pointer-does-not-work.md`。

## 4. 注入崩溃（auto_assemble 后游戏崩）

**可能原因**
- `[DISABLE]` 的原始字节与 Enable 保存的不一致。
- 被覆盖的指令是多字节，没用足够 `nop` 补齐。
- `newmem` 改写了寄存器/破坏栈却没保存恢复。
- 分配的内存不可执行（`allocate_memory` 默认 rwx，但手动写区需 `set_memory_protection`）。
- pattern 不唯一导致 `INJECT` 落在错误位置。

**排查（顺序）**
1. 先 `auto_assemble_check(script)` 语法校验，不过不执行。
2. 确认 `copy_memory(INJECT, N)` 保存的原始字节正确，`[DISABLE]` 的 `db` 完全一致。
3. 被覆盖指令多字节 → 用足够 `nop`；或 `assemble_instruction` 确认新指令长度。
4. `newmem` 用 `push`/`pop` 或分配寄存器保存现场；遵循 `mcp/trainer-dev.md` 模板。
5. 注入前 `get_memory_protection(INJECT)`；不可写/执行则 `full_access`/`set_memory_protection`。
6. 崩溃后先 Disable 恢复，再小步调试；必要时 `allocate_memory` + `set_memory_protection(rwx)` 自建跳板。

**参考**：`diagnostics/07-injection-crashes-game.md`、`mcp/trainer-dev.md`。

## 5. 游戏版本更新导致失效

**可能原因**：代码重编译（AOB 特征变）、字段重排（IL2CPP 偏移变）、metadata 更新、反作弊增强。

**排查（按引擎）**
- **IL2CPP**：重新用 Il2CppDumper 生成 `dump.cs`，`diff` 字段偏移；按 `mcp/engine-analysis.md` 的 Class→Field→Offset→CE 验证 重新定位。
- **通用 AOB**：`aob_scan_module_unique(pattern, "game.exe")` 确认特征码是否仍在；变了则 `generate_signature` 重新生成或人工收紧 pattern。
- **指针**：重新 `pointer_rescan` 生成新指针链。
- **RTTI/结构**：`get_rtti_classname` + `dissect_structure` 复核类布局是否变化，更新 `create_structure` 固化。

**参考**：`mcp/engine-analysis.md`、`diagnostics/10-server-side-or-protected-data.md`（权限/保护相关）。

## 6. 连接/环境类

- **ping 失败**：CE 未运行 ce_mcp_bridge.lua（cheatengine-mcp-bridge 仓库）；检查是否看到 `MCP Server Listening on: CE_MCP_Bridge_v99`；确认 MCP 客户端配置路径正确。
- **DBVM 功能报错**：未加载 DBVM；`start_dbvm_watch` 等需先启用 DBVM。
- **BSOD 风险**：务必禁用 CE 设置中「Query memory region routines」。
- **跨平台**：非 Windows 用 `CE_MCP_TRANSPORT=tcp` + `ce_tcp_relay.py`。

## 7. MCP Bridge 实操陷阱（实测确认）

> **验证环境**：CE MCP Bridge v12.0.0 / Windows x64 / Unity IL2CPP 目标 ｜ **验证日期**：2026-08-03
> **衰减类型**：环境相关 —— Bridge 升版后需复检 7.2 / 7.3 / 7.4（这三条是实现缺陷，作者修掉就失效）；
> 7.1 是 x86 硬件断点的体系结构行为，不随版本变化。
>
> 以下为通过 MCP 完成一次完整 AOB 注入时实测踩到的坑，GUI 操作下不会出现，仅 MCP 调用链特有。

**7.1 `get_breakpoint_hits` 报的指令是「写操作之后的下一条」**
- 硬件写断点（`set_data_breakpoint(access_type="w")`）在存储指令**执行完毕后**才触发，RIP 已指向下一条。
- 直接把 `instruction` 当成写入指令会定位错位置（常见表现：命中报的是 `add rsp,20` / `mov rax,...` 之类无关指令）。
- 正解：`disassemble(hit_address - 0x30, count=24)` 向前回溯，找真正的 store（形如 `mov [reg+offset],reg`）及其上游的算术指令。
- 命中记录里的**寄存器快照是关键线索**：若 `RDI = 目标地址 - 0x10`，说明写入形式是 `[RDI+0x10]`，RDI 指向对象结构体基址。

**7.2 单独执行 `[DISABLE]` 段会返回 `nil`**
- MCP 的 `auto_assemble(script)` 默认只解析执行 `[ENABLE]` 段，不保留上次注册的 `INJECT` / `newmem` 符号。
- 因此把 `[DISABLE]` 段单独丢进去必然失败（符号未定义）。
- 正解：禁用时用 `write_memory(inject_address, [原始字节数组])` 直接还原（字节需十进制数组，如 `48 2B DE` → `[72,43,222]`），再 `read_memory` 复核。
- 重新启用直接跑完整 `[ENABLE]` 脚本即可；`alloc` 会重新分配 newmem（旧 code cave 泄漏但无害，跳转会自动重定位）。

**7.3 `save_table` 路径必须 ASCII + 正斜杠**
- 中文文件名或反斜杠路径会触发 `JSON Parse error`，报错信息不指向路径问题，容易误判。
- 正解：`save_table("C:/path/to/table_name.ct")`，全 ASCII 文件名。

**7.4 `create_memory_record` 挂不了注入脚本**
- 它只能创建「地址监视」型记录（description + address + var_type），无法把 AA 注入做成 CT 里可勾选的脚本条目。
- 通过 MCP 打进进程的补丁**不会**自动写入 CT，`save_table` 存下来的表里没有它。
- 正解：把 AA 脚本单独输出成 `.txt` 交付，让用户在 CE 里 `Ctrl+A`（Auto Assemble）→ 粘贴 → Execute → 生成可勾选记录 → 自行 Save 成 .ct。

**7.5 用户已在 CE 里找好地址时，别让他手敲**
- `get_address_list(offset, limit)` 可直接读出 CE 地址列表里的全部记录（address / type / value / description），再 `read_integer` 复核即可。

通用兜底：先 `ping` → 再 `pause_process` 排除瞬态 → 读错误信息 → 回到对应 diagnostics / mcp 文档。

### 交付 CT 时手工构造注入条目
`save_table` 只导出 CE 地址列表里的条目，MCP `auto_assemble` 的注入不在其中，导出的 CT 会「看着像成功但没有功能」。正确做法是手写 CT XML，把 AA 脚本作为条目：

```xml
<CheatEntry>
  <ID>1</ID>
  <Description>"[ 无限子弹 ]"</Description>
  <VariableType>Auto Assembler Script</VariableType>
  <AssemblerScript>[ENABLE]
aobscanmodule(INJECT, GameAssembly.dll, ...)
alloc(newmem,512,INJECT)
label(return)
newmem:
  ...
  jmp return
INJECT:
  jmp newmem
  nop
return:
registersymbol(INJECT)

[DISABLE]
INJECT:
  db XX XX XX XX XX XX
unregistersymbol(INJECT)
dealloc(newmem)</AssemblerScript>
</CheatEntry>
```

要点：
- `VariableType` 必须是 `Auto Assembler Script`，脚本放 `<AssemblerScript>` 节点内。
- `[ENABLE]` 末尾加 `registersymbol(INJECT)`、`[DISABLE]` 开头用该符号并 `unregistersymbol` —— 否则勾掉时找不到 INJECT，无法还原原字节。
- **注释里绝对不能出现裸 `<`**（`&` `>` 同理）。写 `// sub rbx,rsi <-- skipped` 会让 CE 报
  `无效的作弊表格 (line N pos M) Name starts with invalid character` —— XML 把 `<-` 当成标签名了。
  改写成纯文字（`... is skipped here`）或转义成 `&lt;`。AOB 的 `??` 通配和逗号无需处理。
- 写完必须校验：`python -c "import xml.etree.ElementTree as ET; ET.parse(r'x.CT')"`，再用
  `auto_assemble_check` 校验脚本本身。两道都过才交付。
- **交付前先把 MCP 直接打进内存的补丁还原**（`write_memory` 写回原字节）。否则原字节已被 `E9 ...`
  覆盖，用户加载 CT 勾选时 `aobscanmodule` 扫不到特征码而失败。还原后用
  `aob_scan_module_unique` 确认能重新命中，再交给用户。
- **不要把动态地址写进 CT**。扫描得到的堆地址重启即失效，交付出去等于废条目。正确做法是在
  注入点把基址寄存器存下来，条目改成指针型：

  ```
  alloc(base,8,INJECT)
  registersymbol(base)
  newmem:
    mov [base],rdi     // rdi = 结构体基址，CE 会自动汇编成 rip 相对（48 89 3D ...，7 字节）
    ...
  ```
  ```xml
  <Address>base</Address>
  <Offsets><Offset>10</Offset></Offsets>
  ```
  注意：`mov [base],reg` 不改标志位也不占寄存器，插在 newmem 里安全；但符号要在
  `[DISABLE]` 里 `unregistersymbol` + `dealloc`。指针要等目标代码路径**首次执行**后才有值。
