# Breakpoint Does Not Trigger（断点不命中）

## Symptoms
对某地址设置 "Find what accesses/writes" 或调试器断点后，触发目标动作时 CE 不记录任何访问、不暂停、或断点一设即失效。

## Check Order
1. 确认代码被执行：该地址的值在目标动作中是否真的被读写；若值根本没变化，自然不会命中（先用扫描确认值确实在变）。
2. 确认地址仍有效：动态地址可能已被释放/重新分配，断点设在旧地址上。重新定位地址后再设断点（见 `diagnostics/03-address-changes-after-restart.md`）。
3. 选择合适的断点类型：
   - "Find what accesses/writes" 是硬件断点式钩子，适合定位指令，最多 4 个。
   - 软件断点（`int3`/`0xCC`）会改写字节，若代码在校验完整性会被检测。
   - 若硬件断点被占用或失效，改用 AOB 访问断点或 `workflows/06`/`07` 的代码定位法。
4. 检查页面保护：目标页可能带 PAGE_GUARD 或不可执行，导致断点无效。用 Memory View 查看页面属性。
5. 排除反调试：某些目标检测调试器/断点后清除或绕行。现象：单步能进、断点不命中、或附加后行为异常。此时改用 AOB 注入式钩子而非调试器断点（见 `references/07-debugger-and-breakpoints.md`、`references/15-protection-and-limitations.md`）。
6. 确认附加方式：是否以管理员权限附加、是否附加到正确进程（同名子进程/启动器 vs 实际游戏进程）。
7. 改用 "Find what accesses" 替代 "writes"（或反之）：读取路径和写入路径指令不同，先确认你想抓的是哪一类。

## Evidence to Collect
- CE 版本与目标版本（32/64 位）
- 断点地址、断点类型（硬件/软件/access/write）
- 目标动作触发后是否值变化、是否命中
- 页面保护属性
- 是否以管理员附加、附加的进程名
- 是否怀疑反调试（附加后行为异常）

## Resolution Criteria
触发目标动作后，CE 立即记录到访问/写入该地址的指令并暂停（或列出指令列表），且该指令可被进一步用于代码注入或对象过滤。

## Quick Sanity Check（快速验证）
- 触发动作时该地址的值是否真的变化？若不变化，断点自然不会命中，先用扫描确认值在变。
- 换一种断点类型：`Find what accesses` 与 `Find what writes` 命中的指令不同，先确认你要抓读还是写。
- 附加后目标行为是否异常（崩溃/卡顿/退出）？若是，可能存在反调试，改用 AOB 注入式钩子。

## Related Files
- `workflows/06-find-accessing-code.md` — 查找访问代码
- `workflows/07-find-writing-code.md` — 查找写入代码
- `references/07-debugger-and-breakpoints.md` — 调试器与断点
- `references/15-protection-and-limitations.md` — 反调试/防护限制
- `diagnostics/03-address-changes-after-restart.md` — 地址已失效导致断点不命中
