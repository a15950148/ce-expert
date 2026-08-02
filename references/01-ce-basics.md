# CE Basics（Cheat Engine 基础）

## What CE is（CE 是什么）
Cheat Engine 是一款面向单机、离线、教育及个人用途的内存分析工具。它扫描目标进程的虚拟内存，列出候选地址，并提供调试器、结构体查看、代码注入（Auto Assembler）、Lua 脚本与自动化能力。

## Core concepts（核心概念）
- **扫描（Scan）**：按数值类型与变化规律，从海量内存中筛出可能地址。
- **地址（Address）**：内存中的一个位置，不一定是"逻辑对象"本身。
- **指针（Pointer）**：把某个内存值当作另一块地址来解读，用于稳定访问动态对象。
- **调试器（Debugger）**：在指令层面观察"谁读/写/执行"了某个值。
- **Auto Assembler（AA）**：CE 的脚本语言，用于代码注入与符号定义。
- **Lua**：用于自动化、热键、表单 UI、定时器与训练器。

## Minimum workflow（最小工作流）
Attach（附加进程）→ Scan（扫描）→ Change value（改变数值）→ Filter（筛选）→ Verify（验证）→ Determine stability（判断稳定性）→ Build reusable record/script（构建可复用记录/脚本）。

## Important distinction（重要区分）
- 显示值 ≠ 存储值 ≠ 派生值 ≠ 服务器权威值。
- 一个地址只是位置，不一定是你要改的"对象"。
- 显示数字可能被拷贝、取整、加密、派生，或受别处控制。
- 地址变动不代表只能做指针扫描——代码访问常能揭示稳定的对象路径或注入点。

## Reading guide（阅读指引）
- 新手先看 `references/02-memory-and-process.md`（内存模型）。
- 数值类改值走 `workflows/01`~`07`。
- 复杂对象/共享代码走 `workflows/08`~`11`。
- 工程化（开关/热键/训练器）走 `workflows/13`~`15`。
- 失败时查 `diagnostics/`，法律与边界见 `references/15-protection-and-limitations.md`。
