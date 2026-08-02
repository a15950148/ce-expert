# Find Accessing Code（查找访问代码）

## Goal
找到**读取**目标数值的指令，用于理解数值如何被使用（显示、判定、计算），或作为后续注入的切入点。成功条件：得到稳定命中的指令地址、字节与寄存器上下文。

## Prerequisites
- 已找到目标地址（来自 `workflows/01`/`02`/`03`）。
- 能触发该数值被使用的动作。
- 已读 `references/07-debugger-and-breakpoints.md`。

## Procedure
1. 在地址列表选中目标地址，右键 → Find out what accesses this address。
2. 在弹出的调试器窗口中，回到目标执行相关动作（如角色被判定、数值被显示）。
3. 观察出现的指令列表，记录：
   - 指令地址（是否 `module+offset` 形式）
   - 指令字节（用于 AOB）
   - 寄存器值（尤其源寄存器）
   - 调用频率与是否多对象命中
4. 反复触发，确认指令稳定出现（不止一次）。
5. 双击指令查看反汇编上下文，理解它如何读取该值。

## Decision Branches
- 窗口无指令出现：动作未触发读取，换更直接的用法（如让数值参与判定）。
- 多条指令：优先选模块内、调用频率与逻辑相关的那条。
- 多对象命中同一条：进入 `workflows/11-handle-shared-code.md`。
- 目标检测调试器崩溃：见 `diagnostics/` 相关项。

## Verification
- 指令在多次触发中稳定出现。
- 记录：指令地址、字节、寄存器、调用上下文。
