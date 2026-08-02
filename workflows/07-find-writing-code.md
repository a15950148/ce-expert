# Find Writing Code（查找写入代码）

## Goal
找到**改写**目标数值的指令，这是锁血、改金币、固定数值等修改的核心切入点。成功条件：得到稳定命中、可定位（模块内）的写入指令及其字节。

## Prerequisites
- 已找到目标地址。
- 能触发数值被改变的动作（受伤、获得、结算）。
- 已读 `references/07-debugger-and-breakpoints.md`。

## Procedure
1. 在地址列表选中目标地址，右键 → Find out what writes to this address。
2. 回到目标执行改变该数值的动作（如受到伤害）。
3. 记录弹窗中的指令：地址、字节、寄存器、调用频率。
4. 反复触发，确认指令稳定（多条时按上下文筛选）。
5. 双击查看反汇编，确认是「真正写入该值」的指令（而非缓存/拷贝）。
6. 用该指令的字节构造 AOB（见 `workflows/12-create-aob-injection.md` 或 `references/10-aob-and-code-injection.md`）。

## Decision Branches
- 无写入指令：数值可能由服务器下发或派生计算，见 `diagnostics/10-server-side-or-protected-data.md`。
- 写入点是多层调用：向上回溯调用方，找稳定的逻辑写入点。
- 多对象共用该指令：进入 `workflows/11-handle-shared-code.md`。
- 改写入逻辑导致崩溃：见 `diagnostics/07-injection-crashes-game.md`。

## Verification
- 指令在多次改变数值的动作中稳定命中。
- 记录：指令地址（模块形式）、字节、寄存器、调用频率。

## Related Files
- `references/07-debugger-and-breakpoints.md` — 调试器与断点原理
- `references/10-aob-and-code-injection.md` — AOB 与代码注入原理
- `workflows/06-find-accessing-code.md` — 查找读取代码（对比）
- `workflows/12-create-aob-injection.md` — 用找到的指令创建 AOB 注入
- `diagnostics/05-breakpoint-does-not-trigger.md` — 断点不命中时排查
- `diagnostics/10-server-side-or-protected-data.md` — 无写入指令时的判断
