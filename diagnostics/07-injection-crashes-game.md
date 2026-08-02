# Injection Crashes Game（注入导致崩溃）

## Symptoms
启用 AOB 注入脚本后，目标立即崩溃、卡死，或在触发相关动作时崩溃。

## Check Order
1. 确认覆盖边界合法：jmp 覆盖的指令必须**整条替换**，不能切断一条指令的中间（见 `references/09-auto-assembler.md`）。
2. 确认原指令被补跑：被 jmp 跳过的原指令（写值、计算）必须在 code cave 里重放，否则逻辑缺数据崩溃。
3. 确认寄存器未被破坏：注入代码若改了 `RAX`/`RCX` 等调用者保存寄存器却未恢复，会破坏调用方 → 用 `push`/`pop` 或改用保留寄存器。
4. 确认内存页可执行/可写：分配的内存用 `fullAccess` 或 `alloc`（默认可执行）；写只读页需去掉保护。
5. 确认对齐：SSE/AVX 指令要求 16 字节对齐，未对齐访问会崩溃。
6. 确认 AOB 唯一：解析到多个地址时，脚本可能改错地方（见 `workflows/12-create-aob-injection.md`）。
7. 逐步隔离：先只放原指令 + 跳回（空注入），确认不崩，再逐步加自定义逻辑定位崩溃点。
8. 查阅 `references/08-x86-x64-assembly.md` 理解指令与寄存器。

## Evidence to Collect
- CE 版本
- 目标版本（32/64 位）
- 注入脚本全文（含 AOB、原指令、自定义逻辑、DISABLE）
- 崩溃时机（启用瞬间 / 触发动作时）
- 注入指令的字节与寄存器
- 崩溃是否可复现

## Resolution Criteria
脚本可稳定启用/禁用，触发相关动作不再崩溃，且 enable→disable→enable 多次反复正常。

## Quick Sanity Check（快速验证）
- 先做「空注入」（只重放原指令 + 跳回，无自定义逻辑），是否仍崩？不崩=问题在自定义逻辑；崩=覆盖边界或寄存器破坏。
- jmp 覆盖的起始字节是否落在一条指令的边界上？切断指令中间会立即崩溃。
- 注入代码是否改动了 `RAX`/`RCX`/`RDX` 等调用者保存寄存器却未 `push`/`pop` 恢复？

## Related Files
- `workflows/12-create-aob-injection.md` — AOB 注入创建流程
- `workflows/11-handle-shared-code.md` — 共享代码过滤（误伤排查）
- `references/09-auto-assembler.md` — Auto Assembler 语法
- `references/08-x86-x64-assembly.md` — x86/x64 指令与寄存器
- `references/10-aob-and-code-injection.md` — AOB 与代码注入原理
- `templates/aa-aob-injection.txt` — AOB 注入模板
- `diagnostics/08-script-enable-failed.md` — 脚本启用报错排查
