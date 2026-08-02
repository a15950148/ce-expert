# Cannot Find Value（找不到数值）

## Symptoms
按预期步骤扫描后，结果数量没有收敛（始终几百上千），或收敛后改值对目标无影响，或首次扫描就报「无结果」。

## Check Order
1. 确认进程：CE 附加的是否为正确进程（同名进程、子进程、启动器 vs 实际游戏进程）。多开/沙箱环境尤其注意。
2. 确认版本：目标版本与已知偏移/教程是否匹配；更新后内部布局可能已变。
3. 确认数值类型：整数值可能存为 Float/Double，反之一样。依次试 4 Bytes、Float、Double（见 `references/03-value-types.md`）。
4. 确认编码：值可能被缩放（显示 100，内存存 1000）、取整或加密。尝试扫描显示值的倍数，或先 Unknown 后 Fuzzy。
5. 确认状态可复现：扫描期间目标是否真的改变了该值。
6. 换扫描策略：已知值用 Exact；未知值用 Unknown Initial + Fuzzy（见 `references/04-scan-types.md`）。
7. 验证地址：收敛后逐个加入列表改值，确认哪个真正映射显示。

## Evidence to Collect
- CE 版本
- 目标版本与平台（32/64 位）
- 扫描设置（类型、扫描类型、数值）
- 每次扫描前后候选数量
- 地址/值在改值前后的变化
- 是否尝试过其他数值类型

## Resolution Criteria
改某个具体地址的值后，目标界面实时、稳定地反映该变化，且能复现。

## Quick Sanity Check（快速验证）
- CE 进程列表里附加的进程名是否与实际游戏进程一致（而非启动器/子进程）？
- 换一种数值类型（4 Bytes ↔ Float ↔ Double）重扫一次，候选数量是否变化？
- 若首次扫描就 0 结果：目标值是否被加密/缩放？改用 Unknown Initial + Fuzzy 重试。

## Related Files
- `diagnostics/02-too-many-results.md` — 扫得到但不收敛的排查
- `diagnostics/10-server-side-or-protected-data.md` — 怀疑服务器控制时的判断
- `workflows/01-modify-known-value.md` — 已知数值修改流程
- `workflows/02-find-unknown-value.md` — 未知数值查找流程
- `references/03-value-types.md` — 数值类型详解
- `references/04-scan-types.md` — 扫描类型详解
