# Debugger and Breakpoints（调试器与断点）

## 找到访问/写入代码
- **Find out what accesses this address**：找到读取或引用该值的代码。当你需要「谁在用这个值做判断/显示」时选它。
- **Find out what writes to this address**：找到改写该值的代码。当你需要「谁在改这个值」时选它（改数值、锁血、改金币都从这儿入手）。

## 记录内容
- 指令地址（instruction address）
- 指令字节（instruction bytes，用于 AOB）
- 寄存器值（register values，尤其是源/目的寄存器）
- 被访问的地址（accessed address）
- 调用频率（call frequency，高频可能是渲染循环，低频可能是逻辑更新）
- 多个对象是否触发同一条指令（判断是否共享代码）

## 验证
- 反复触发目标动作，确认指令稳定命中。一次命中不足以作为证据。
- 对比「玩家动作」与「敌人/其他对象动作」是否都命中同一条指令——若是，则进入 `workflows/11-handle-shared-code.md`。

## 断点类型
- 硬件断点（hardware）：不修改代码，适合反调试环境，数量有限（通常 4 个）。
- 内存断点（memory）：监视内存读写，较慢但覆盖广。
- 执行断点：监视代码执行。

## 注意事项
- 某些目标会检测调试器。若触发异常或无故崩溃，先关闭调试器相关功能，改用观察法（见 `diagnostics/`）。
- 记录的信息是后续写 AOB 注入（references/10）和 Auto Assembler（references/09）的输入。
