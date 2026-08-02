# MCP 工具适配层 (mcp-tools.md)

> 本文件记录 **Cheat Engine MCP Bridge**（FastMCP server name = `cheatengine`）实际暴露的工具。
> 所有名称、参数均从源码 `mcp_cheatengine.py`（cheatengine-mcp-bridge 仓库）与官方命令参考（AI_Context/MCP_Bridge_Command_Reference.md）**逐字提取**，不要臆造工具名。
> 对应适配要求 2。
>
> 约定：地址多为字符串（`"0x..."` 或符号）；偏移为整数列表；返回几乎都含 `success` 字段，**先判 `success` 再取数据**。

---

## A. 进程与模块 (Process & Modules)

### open_process(process_id_or_name: str)
- **功能**：打开并附加到目标进程。
- **参数**：`process_id_or_name`（必填，PID 或进程名如 `"game.exe"`）。
- **返回**：`{success, process_id, process_name}`。
- **场景**：一切分析的第一步。先 `get_process_list` 确认名称/PID。

### get_process_list()
- **功能**：列出系统进程。
- **返回**：`{success, count, processes:[{pid, name}]}`。
- **场景**：不知道进程名/PID 时枚举。

### get_process_info()
- **功能**：当前附加进程的 ID、名称、模块数、架构（x86/x64）。
- **返回**：`{success, process_name, process_id, module_count, modules, used_aob_fallback}`。
- **场景**：确认架构以决定指针/偏移解释方式。

### get_processid_from_name(name: str)
- **返回**：`{success, process_id}` 或 `NOT_FOUND`。
- **场景**：由名称转 PID。

### enum_modules(offset: int=0, limit: int=100)
- **功能**：枚举已加载模块（DLL/EXE）及基址、大小。
- **返回**：`{success, total, offset, limit, returned, modules:[{name, base, size}]}`。
- **场景**：找 `game.exe` 基址、定位模块做 AOB 扫描。

### get_module_size(module_name: str)
- **返回**：`{success, size}`。
- **场景**：配合 AOB 模块扫描范围。

### get_symbol_address(symbol: str)
- **功能**：符号名（如 `"Engine.GameEngine"`）→ 地址。
- **返回**：`{success, address}`。
- **场景**：Unity/UE 符号解析后定位对象。

### get_address_info(address: str, include_modules=true, include_symbols=true, include_sections=false)
- **返回**：该地址所属模块、符号、节信息。
- **场景**：拿到任意地址后判断它落在哪个模块/符号。

---

## B. 内存读取 (Memory Reading)

### read_memory(address: str, size: int=256)
- **返回**：`{success, address, size, data(hex 空格分隔), bytes([int])}`。
- **场景**：dump 一段原始字节做结构/特征分析。

### read_integer(address: str, type: str="dword")
- **功能**：读整数/浮点。`type` ∈ `byte|word|dword|qword|float|double`。
- **返回**：`{success, address, value, hex}`。
- **场景**：读具体数值（金币、血量等）。

### read_string(address: str, max_length: int=256, wide: bool=false, encoding: str="utf8")
- **返回**：`{success, address, value, wide, length}`。
- **场景**：读玩家名、物品名等字符串。

### read_pointer(address: str, offsets: list[int]=None)
- **功能**：从地址读出指针值（可附带偏移链）。
- **返回**：`{success, address, pointer, arch}`。
- **场景**：读单级指针。

### read_pointer_chain(base: str, offsets: list[int])
- **功能**：解析多级指针链，逐步回显。
- **返回**：`{success, base, offsets, final_address, final_value, chain:[{step, address, pointer_value?, offset, hex_offset, description?}]}`。
- **示例返回**：`final_address:"0x12345678", final_value:100, chain:[{step:0,address:"0x00400000",description:"base"},{step:1,address:"0x0050003C",offset:60,hex_offset:"+0x3C",pointer_value:"0x00500000"}]`。
- **场景**：验证 `[[base+0x3C]+0x20]+0x8` 这类指针链是否还指向正确值。

### checksum_memory(address: str, size: int) / md5_memory(address: str, size: int)
- **返回**：内存区域校验和 / MD5 hex。
- **场景**：判断两段内存是否一致（结构比对、版本指纹）。

---

## C. 内存写入 (Memory Writing)

### write_integer(address: str, value: int|float, type: str="dword")
- **返回**：`{success, address, value, type}`。
- **场景**：修改数值（仅在授权、单机、测试用）。

### write_memory(address: str, bytes: list[int])
- **返回**：`{success, address, bytes_written}`。

### write_string(address: str, value: str, wide: bool=false)
- **返回**：`{success, address, length, wide}`。

> ⚠️ 写入属破坏性操作。改前务必记录原值，优先用 `auto_assemble` 的可逆脚本（见 `mcp/trainer-dev.md`）。

---

## D. 扫描 (Scanning)

### scan_all(value: str, type: str="exact", protection: str="+W-C")
- **功能**：首次值扫描。`type` 可为 `exact`/`string` 等；`protection` 默认可写不可执行。
- **返回**：`{success, count}`。
- **场景**：已知当前值（金币=15000）→ 首扫。

### next_scan(value: str, scan_type: str="exact")
- **功能**：在上一轮结果上过滤。`scan_type` ∈ `exact|increased|decreased|changed|unchanged|bigger|smaller`。
- **返回**：`{success, count}`。
- **场景**：改变数值后再次扫描收敛结果（对应「未知值」流程用 `increased/decreased/changed`）。

### get_scan_results(offset: int=0, limit: int=100, max: int=None)
- **返回**：`{success, total, offset, limit, returned, results:[{address, value}]}`。
- **场景**：读取扫描命中地址列表，挑候选做验证。

### aob_scan(pattern: str, protection: str="+X", limit: int=100)
- **功能**：字节数组（AOB）扫描。`pattern` 用空格分隔十六进制，未知字节用 `??`，如 `"48 89 5C 24 ?? 48 89 74 24"`。
- **返回**：`{success, pattern, count, addresses:[{address, value}]}`。
- **场景**：定位函数特征码、注入点。

### aob_scan_unique(pattern: str, protection: str="+X")
- **返回**：唯一匹配地址或错误（多于一个会报错）。
- **场景**：确认某段代码在进程中只出现一次，适合做稳定注入锚点。

### aob_scan_module(pattern: str, module_name: str, protection: str="+X")
### aob_scan_module_unique(pattern: str, module_name: str, protection: str="+X")
- **功能**：限定在某个模块（如 `game.exe`）内扫描；`_unique` 要求唯一。
- **场景**：大型游戏里避免跨模块误匹配。

### search_string(string: str, wide: bool=false, limit: int=100)
- **返回**：字符串搜索命中。
- **场景**：定位硬编码字符串（如错误码、按钮文本）。

### generate_signature(address: str)
- **返回**：该地址处的唯一 AOB 签名。
- **场景**：拿到一个地址后自动生成可复用的注入特征。

### pointer_rescan(value: str, previous_results_file: str=None)
- **功能**：在地址变化后，用当前值对旧结果做指针重扫，找出能稳定指向该值的基址+偏移。
- **返回**：`{success, count}`（找到的指针数量）。
- **场景**：重启后地址变了 → 用上次扫描结果做指针扫描。

### create_persistent_scan(name: str) / persistent_scan_first_scan(name, value, type="dword", scan_option="exact") / persistent_scan_next_scan(name, value=None, scan_option="exact") / persistent_scan_get_results(name, offset, limit) / persistent_scan_destroy(name)
- **功能**：持久扫描会话，可跨多轮过滤而不依赖全局扫描状态。
- **场景**：复杂未知值流程（多步 increased/decreased/changed）的稳妥做法。

---

## E. 指针分析 (Pointer Analysis)

### analyze_pointer_access(instruction: str, registers: dict, accessed_address: str=None, is_64bit: bool=None)
- **功能**：分析一条汇编指令如何访问某地址（基址寄存器、位移、结构体基址）。
- **返回**：基址寄存器、位移、结构体基址分析。
- **场景**：从反汇编里识别 `[reg+offset]` 形式的访问，定位结构体字段。

### validate_pointer_chains(chains: list, target: str, include_misses: bool=false)
- **功能**：批量验证候选指针链是否真的指向 `target` 值。
  `chains:[{base, offsets:[int,...]}]`，`target` 为已知值地址，最多 5000 条。
- **返回**：`{success, target, total, matched, unreadable, matches:[{base, offsets, final_address, final_value}], misses?}`。
- **示例**：`chains:[{"base":"0x7FF600000000","offsets":[16,0,36]}], target:"0x1F2A4"` → `matched:1`。
- **场景**：指针扫描得到一堆候选后，用 `validate_pointer_chains` 确认哪些真正有效（对应人工「指针扫描 → 验证」）。

---

## F. 分析与反汇编 (Analysis & Disassembly)

### disassemble(address: str, count: int=20, offset: int=0, limit: int=100)
- **返回**：`{success, start_address, instruction_count, instructions:[{address, bytes, instruction, size}]}`。
- **场景**：看某个地址附近的汇编，定位写入/读取指令。

### get_instruction_info(address: str)
- **返回**：单条指令详情（大小、字节、操作码）。

### find_function_boundaries(address: str, max_search: int=4096)
- **返回**：函数起止地址。
- **场景**：确定要 hook/inject 的函数范围。

### analyze_function(address: str)
- **返回**：函数内 CALL 指令列表。
- **场景**：理解函数调用关系。

### find_references(address: str, offset: int=0, limit: int=50)
- **功能**：找哪些代码访问了某地址（即「谁读/写了这里」）。
- **返回**：`{success, target, arch, total, returned, references:[{address, instruction}]}`。
- **场景**：定位「写入金币的指令」——对应人工「Find out what writes to this address」。

### find_call_references(function_address: str, offset: int=0, limit: int=100)
- **返回**：调用该函数的位置 `callers:[{caller_address, instruction}]`。
- **场景**：回溯调用链（谁调用了扣血函数）。

### dissect_structure(address: str, size: int=256)
- **功能**：让 CE 自动推测该地址处的结构布局。
- **返回**：推测出的结构（字段偏移/类型）。
- **场景**：分析对象字段（配合 `create_structure` 固化）。

### get_rtti_classname(address: str)
- **功能**：通过 C++ RTTI 识别对象类名。
- **返回**：类名字符串。
- **场景**：UE/非 Unity C++ 游戏识别对象类型。

---

## G. 调试与断点 (Debug & Breakpoints)

### set_breakpoint(address: str, id: str=None, capture_registers: bool=true, capture_stack: bool=false, stack_depth: int=16)
- **功能**：硬件执行断点。
- **返回**：`{success, id, address, slot(0-3), method:"hardware_debug_register"}`。
- **场景**：在目标指令处中断，抓寄存器上下文。

### set_data_breakpoint(address: str, id: str=None, access_type: str="w", size: int=4)
- **功能**：硬件数据断点（`access_type` ∈ `r|w|e`）。
- **返回**：`{success, id, address, slot, access_type}`。
- **场景**：监控某地址被谁写入（等价于「Find what writes」，但走硬件断点）。

### get_breakpoint_hits(id: str=None, clear: bool=false, offset=0, limit=100)
- **返回**：`{success, count, hits:[{id, address, timestamp, breakpoint_type, registers?, stack?}]}`。
- **场景**：读取断点命中时的寄存器/堆栈，定位访问代码。

### remove_breakpoint(id: str) / list_breakpoints() / clear_all_breakpoints()
- **场景**：清理断点，避免残留影响后续分析。

### start_dbvm_watch(address: str, mode: str="w", max_entries: int=1000)
- **功能**：DBVM（Ring -1 虚拟机监视器）隐形监视，对方无法检测调试器。
- **返回**：`{success, status, virtual_address, physical_address, watch_id, mode, note}`。
- **场景**：反调试/反作弊游戏里「Find what writes」的隐形方案。

### stop_dbvm_watch(address: str)
- **返回**：`{success, virtual_address, physical_address, mode, hit_count, duration_seconds, hits:[{hit_number, instruction_address, instruction, registers}]}`。

### poll_dbvm_watch(address: str, max_results: int=1000)
- **返回**：同上 hits，不停止监视。

### pause_process() / unpause_process()
- **功能**：冻结/恢复目标进程。
- **场景**：扫描/分析时暂停，避免数值被游戏逻辑改写造成误判。

### debug_is_debugging()
- **返回**：`{success, is_debugging}`。

---

## H. 内存分配与保护 (Allocation & Protection)

### allocate_memory(size: int, base_address: str=None, protection: str="rwx")
- **返回**：`{success, address, size}`。
- **场景**：为代码注入/数据垫块分配可执行内存。

### free_memory(address: str, size: int=0)
### set_memory_protection(address: str, size: int, read: bool=true, write: bool=true, execute: bool=true)
### full_access(address: str, size: int)
- **场景**：注入前把目标区域设为可写/可执行。

### copy_memory(source: str, size: int, dest: str=None, method: int=0)
- **返回**：dest 地址（dest=None 时由 CE 分配）。
- **场景**：保存原始代码字节以便恢复（注入必备）。

### compare_memory(addr1: str, addr2: str, size: int, method: int=0)
- **返回**：`{equal, first_diff_index}`。

### get_memory_regions(max: int=100) / enum_memory_regions_full(offset=0, limit=100, max=None)
- **场景**：了解内存布局、找合适的注入/数据区域。

---

## I. 代码注入与执行 (Code Injection & Execution)

### auto_assemble(script: str)
- **功能**：执行 Auto Assembler 脚本（启用/禁用脚本、分配内存、写注入）。
- **返回**：`{success, message}`。
- **场景**：落地所有可复现修改（Enable/Disable 脚本）。**优先于直接 write_integer**。

### auto_assemble_check(script: str, enable: bool=true, target_self: bool=false)
- **返回**：`{success, valid, errors}`。
- **场景**：注入前先校验脚本语法。

### assemble_instruction(line: str, address: str=None, preference: int=0, skip_range_check: bool=false)
- **功能**：汇编单行指令为机器码。
- **返回**：`{success, bytes, size, hex}`。
- **场景**：构造跳转/补丁字节（AOB 注入的「新指令」部分）。

### generate_code_injection_script(address: str)
- **功能**：在指定地址自动生成代码注入（hook）脚本骨架。
- **返回**：`{success, script}`。
- **场景**：快速得到带原始指令保存的注入模板，再自行补全 Enable/Disable。

### generate_api_hook_script(address: str, target_address: str, code_to_execute: str="")
- **返回**：`{success, script}`。
- **场景**：生成 API hook（调用某函数前/后执行代码）。

### inject_dll(filepath: str, skip_symbol_reload: bool=false)
- **返回**：`{success, path, base_address?}`。
- **场景**：注入 DLL 训练器/钩子（仅在授权测试环境）。

### execute_code(address: str, param: int=0, timeout: int=-1)
- **返回**：`{success, return_value}`（EAX/RAX）。
- **场景**：在目标进程执行一小段已写入的代码。

### execute_code_ex(call_method: int, timeout: int, address: str, args: list=None)
### execute_method(address: str, instance: str, args: list=None, call_method: int=0, timeout: int=-1)
- **场景**：调用对象方法（配合 `get_symbol_address` 拿方法符号）。

### compile_c_code(source: str, address: str=None, target_self: bool=false, kernelmode: bool=false)
- **返回**：`{success, symbols, errors}`。
- **场景**：用 C 写复杂注入逻辑并编译进进程。

---

## J. 符号管理 (Symbols)

### register_symbol(name: str, address: str, do_not_save: bool=false)
- **返回**：`{success, name, address}`。
- **场景**：把确认好的基址/函数命名，便于后续 `read_pointer_chain(base="sym")` 引用。

### get_symbol_info(name: str) / unregister_symbol(name) / enable_windows_symbols()
- **场景**：读取符号、清理、开启 Windows PDB 符号。

---

## K. 脚本 (Scripting)

### evaluate_lua(code: str)
- **功能**：在 CE 中执行任意 Lua。
- **返回**：`{success, result}`（result 为字符串）。
- **场景**：需要 CE Lua API 完成但无专用工具时的兜底；也可用于高级结构/UI 操作。
- ⚠️ 与人工流程不同，AI 通常优先用上面的专用工具；`evaluate_lua` 仅作补充。

---

## L. Cheat Table (Cheat Table)

### load_table(filename: str, merge: bool=false)
- **返回**：`{success, path, entry_count}`。
- **场景**：载入已有 .CT（含地址、脚本、Lua）。

### save_table(filename: str, protect: bool=false)
- **返回**：`{success, path}`。
- **场景**：把分析结果固化为 .CT 交付。

### get_address_list(offset: int=0, limit: int=100)
- **返回**：`{success, total, returned, records:[...]}`。
- **场景**：枚举表中记录。

### create_memory_record(description: str, address: str, var_type: str="dword")
### get_memory_record(id: int=None, description: str=None)
### get_memory_record_value(id: int)
### set_memory_record_value(id: int, value: str)
### delete_memory_record(id: int)
- **场景**：程序化构建 Cheat Table（对应人工「添加地址」→「保存 CT」）。

---

## M. 结构管理 (Structure Management)

### create_structure(name: str) → {success, structure_id}
### get_structure_by_name(name: str) → {success, structure_id, name, element_count, size}
### add_element_to_structure(structure_id: int, name: str, offset: int, type: str) → {success, element_index}
### get_structure_elements(structure_id: int) → {success, elements}
### export_structure_to_xml(structure_id: int) → {success, xml}
### delete_structure(structure_id: int)
- **场景**：把 `dissect_structure` / `analyze_pointer_access` 推测出的字段固化成 CE 结构，便于反复复用（对象分析、IL2CPP 字段偏移记录）。

---

## N. 其他有用工具（简述）

- `get_scan_results` / `enum_memory_regions_full`：分页读取扫描/区域结果。
- `get_memory_protection(address)`：读取页保护，注入前确认。
- `create_section(size)` / `map_view_of_section(handle, address, size)` / `allocate_shared_memory(name, size)`：共享内存（多工具协作）。
- `find_window` / `send_window_message` / `get_window_process_id`：窗口级定位（配合 `get_processid_from_name`）。
- `ping()`：连通性/版本探测（首步验证）。
- `read_process_memory_cr3` / `write_process_memory_cr3` / `dbk_get_cr3`：DBVM/DBK 内核态内存读写（需驱动）。

> 注：源码另含 UI/多媒体类（beep、speak_text、play_sound、set_progress_*、show_message、input_query 等），与本分析 Skill 无关，未展开；如确需可在命令参考中查到。

---

## 工具总数与权威性

- 源码共 **150+** 个 `@mcp.tool()` 工具（server name `cheatengine`）。
- 本文件所列名称**全部逐字取自源码**，可作 Skill 内映射的权威来源。
- 新增/变更工具时，**以 `mcp_cheatengine.py` 中的 `@mcp.tool()` 函数名为准**，不要凭记忆补全。
