# Modify Known Value（修改已知值：金币/弹药/等级等）

## Goal
锁定或改写一个**当前可见、可复现变化**的数值（如金币、弹药、经验），使其在目标里持续保持设定值或按预期变化。成功条件：在目标重新进入相关界面/动作后仍保持预期效果。

## Prerequisites
- 已附加正确目标进程。
- 目标状态可复现（能在同一界面反复操作）。
- 已读 `references/03-value-types.md` 与 `references/04-scan-types.md`。

## Procedure
1. 在目标里读取当前数值（如金币 = 1500），记下显示类型（整数/小数）。
2. CE 选择对应数值类型，首次扫描（First Scan）输入当前值。
3. 回到目标，改变该数值（消费/获得），得到新值（如 1450）。
4. 在 CE 用新值再次扫描（Next Scan），缩小结果。
5. 重复 3–4，直到地址列表只剩少量（1–10 个）。
6. 双击地址加入地址列表，手动改值验证是否对目标生效。
7. 确认生效的地址，右键 → 设为冷冻（Freeze）以持续锁定，或用脚本写入。
8. 测试：再次改变目标里的数值，确认锁定值不被覆盖。

## Decision Branches
- 扫不到：见 `diagnostics/01-cannot-find-value.md`。
- 有多个候选且不确定哪个真正生效：逐一改值测试，或结合写入代码定位（`workflows/07-find-writing-code.md`）。
- 重启后失效：转入 `workflows/03-find-dynamic-address.md`。
- 多个对象同时被改（敌人也变）：见 `workflows/11-handle-shared-code.md`。

## Verification
- 改值后目标界面实时反映；冷冻后目标动作无法改变该值。
- 记录：数值类型、最终地址、扫描步骤、冷冻设置。

## Related Files
- `references/03-value-types.md` — 数值类型选择
- `references/04-scan-types.md` — 扫描类型选择
- `examples/01-money.md` — 金币修改完整实例
- `diagnostics/01-cannot-find-value.md` — 找不到值时排查
- `diagnostics/02-too-many-results.md` — 结果不收敛时排查
- `workflows/07-find-writing-code.md` — 多候选时用写入代码定位
- `workflows/03-find-dynamic-address.md` — 重启后地址失效时处理
