# AI Workflow（AI 驱动的分析流程）

> 把「人工在 CE GUI 点击」的教程流程，重构为 AI Agent 可执行的循环。
> 对应适配要求 3。工具名一律来自 `mcp/mcp-tools.md`（不要硬编码假设）。

## 1. 核心循环（6 步）

```
┌──────────────────────────────────────────────────────────┐
│ ① 分析用户目标  →  用户到底想找/改什么？（值？地址？代码？） │
│ ② 判断变量类型  →  已知值 / 未知值 / 动态地址 / 代码写入 / 结构 │
│ ③ 选择 MCP 工具  →  查 mcp-tools.md / tool-mapping.md 决策树   │
│ ④ 执行分析      →  调用对应 MCP 工具，按需分页/迭代            │
│ ⑤ 解析结果      →  按 mcp/result-parsing.md 解读返回          │
│ ⑥ 决定下一步    →  收敛？验证？换方法？做注入/固化 CT？        │
└───────────────┬──────────────────────────────────────────┘
                │ 未收敛 / 有新线索
                └──────────────► 回到 ② / ③
```

**Skill 在每个节点的职责**（不写 MCP 实现，只做推理与决策）：
- ① 澄清目标、识别风险（是否合规、是否单机授权）。
- ② 把自然语言映射到变量类型。
- ③ 从「工具选择决策树」挑工具。
- ④ 组装正确的参数（地址格式、偏移列表、扫描类型）。
- ⑤ 读懂 JSON 返回，抽取关键字段。
- ⑥ 判断是否达到「可复现、可验证、可关闭」的闭环，否则进入下一轮。

## 2. 各步骤落地的 MCP 工具

| 步骤 | 常用工具 |
|---|---|
| ① 目标分析 | 无（纯推理）；必要时 `get_process_info` 确认架构 |
| ② 类型判断 | 无（推理） |
| ③ 选工具 | `mcp-tools.md`、`mcp/tool-mapping.md` 决策树 |
| ④ 执行 | `scan_all`/`next_scan`/`read_*`/`aob_scan_*`/`find_references`/`disassemble`/`auto_assemble` 等 |
| ⑤ 解析 | 见 `mcp/result-parsing.md` |
| ⑥ 决策 | 依据解析结论回流到 ②/③ 或收尾 |

## 3. 端到端示例

### 场景 A：已知数值（金币 = 15000）
1. **目标**：锁定金币。
2. **类型**：已知精确值。
3. **工具**：`scan_all("15000", "dword")`。
4. **执行**：得到 `count`。若 `count` 很大 → 让用户改金币后 `next_scan("15010","exact")` 收敛；直到 `count` 为 1~几个。
5. **解析**：`get_scan_results` 取出候选地址，用 `read_integer` 复核是否等于当前值。
6. **决定**：唯一候选 → 用 `auto_assemble` 写可逆锁定脚本，或 `create_memory_record` + `save_table` 固化为 CT。

### 场景 B：未知数值（血条忽高忽低）
1. **目标**：找到血量地址。
2. **类型**：未知初始值，但可观察增减。
3. **工具**：首扫用 `scan_all` 配合 unknown 思路——首轮先建立候选集（如先 `next_scan` 用 `changed`/`unchanged` 收敛），或直接用 `persistent_scan_*` 会话。
4. **执行**：受伤后 `next_scan(scan_type="decreased")`，回血后 `next_scan(scan_type="increased")`，稳定后 `next_scan(scan_type="unchanged")` 排除。
5. **解析**：`get_scan_results` 候选收敛到个位数。
6. **决定**：逐个 `read_integer` 验证；确定后转入「定位修改来源」或「稳定修改」。

### 场景 C：动态地址（重启失效）
1. **目标**：重启后仍能用。
2. **类型**：地址基址+偏移。
3. **工具**：用重启前的扫描结果 `pointer_rescan(value)`，或手工 `read_pointer_chain(base, offsets)` 验证候选链。
4. **执行**：`validate_pointer_chains(chains, target)` 批量确认哪些链真的指向目标值。
5. **解析**：`matches` 中 `base` 多为模块基址（`game.exe`+偏移）或静态符号。
6. **决定**：取稳定的 `base+offsets` → 写成指针型 `auto_assemble` 脚本或 CT 记录（勾选指针）。

### 场景 D：定位「谁改写了这个值」
1. **目标**：找到写入血量的指令（做无敌/不减）。
2. **类型**：代码访问定位。
3. **工具**：`find_references(address)`（软件法）或 `start_dbvm_watch(address, mode="w")`（隐形法，反调试游戏）。
4. **执行**：触发数值变化 → `get_breakpoint_hits` / `stop_dbvm_watch` 拿到 `instruction_address` 与 `instruction`。
5. **解析**：`disassemble(instruction_address)` 看上下文，识别写入指令（如 `mov [reg+off], eax`）。
6. **决定**：在该地址做 `aob_scan_module_unique` 锚点 → 进入场景 E 注入。

### 场景 E：稳定修改（代码注入）
1. **目标**：让血量不减。
2. **类型**：需稳定、可开关的修改。
3. **工具**：`aob_scan_module_unique(pattern, "game.exe")` 定位函数特征；`generate_code_injection_script(address)` 生成骨架。
4. **执行**：补全 Enable（跳转到新代码、设血量、跳回）/ Disable（恢复原始字节）/ 原始代码恢复 / 错误处理，见 `mcp/trainer-dev.md`。
5. **解析**：`auto_assemble_check(script)` 验证语法 → `auto_assemble(script)` 启用。
6. **决定**：`enable→disable→enable` 三次验证 + 重启验证后，用 `save_table` 交付。

## 4. 与原人工 workflow 的关系

- 原 `workflows/` 目录下的文件是**人工 GUI 操作知识库**，仍是底层参考（原理、判定、坑点全在）。
- 本文件是**AI 用 MCP 工具等价实现**的主线。两者通过 `mcp/tool-mapping.md` 一一映射。
- 当 AI 遇到原理性疑问（如「如何判断 shared code」「Mono 结构怎么读」），回查 `references/` 与 `workflows/`，再翻译成 MCP 工具调用。

## 5. 闭环验收标准（每次修改都要满足）

1. **可复现**：用同样流程能再次得到相同地址/脚本。
2. **可验证**：`read_integer` / `read_pointer_chain` 复核值正确；注入后行为符合预期。
3. **可关闭**：`auto_assemble` 脚本 Disable 后游戏恢复原始行为；`remove_breakpoint` 清理断点。
4. **可重启**：指针/注入锚点在目标程序重启后仍有效（否则回到场景 C/E 加固）。
