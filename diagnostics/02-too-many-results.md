# Too Many Results（扫描结果不收敛）

## Symptoms
按 `workflows/01`/`02` 多次扫描后，候选数量始终不下降（停留在几百、几千甚至上万），或改值测试时没有一个地址对目标生效。

## Check Order
1. 确认数值类型正确：整数可能存为 Float/Double（血量 100 实际存 100.0），反之亦然。依次试 4 Bytes、Float、Double（见 `references/03-value-types.md`）。
2. 确认扫描类型匹配：已知且会变化的值用 Exact；完全未知或显示值不可信时用 Unknown Initial + Fuzzy（见 `references/04-scan-types.md`）。
3. 确认值真的在变化：扫描期间目标是否真的改了该值；若值不变，Next Scan 等于在原集合里再筛一次，自然不收敛。
4. 排除显示值被缩放/取整/加密：显示 100 但内存存 1000、或存 (100*2+1)。尝试扫描显示值的倍数、或先 Unknown 再 Fuzzy。
5. 启用 Fast Scan / 调整对齐：CE 的 Fast Scan 按对齐跳过大部分内存，能显著减少候选；确认对齐宽度（4/8 字节）与数值类型一致。
6. 缩小扫描范围：用 Memory View 选定模块或区域后扫描，避免全进程扫到大量无关内存。
7. 改用写入代码定位：若数值确实在变但扫不出来，直接对疑似地址用 "Find what writes"（见 `workflows/07-find-writing-code.md`），绕过扫描收敛问题。
8. 重启 CE 内存快照：旧扫描结果可能残留干扰，新扫描前清空地址列表并 New Scan。

## Evidence to Collect
- CE 版本与目标版本（32/64 位）
- 数值类型、扫描类型、每次扫描的输入值
- 每次扫描前后候选数量变化曲线
- 是否启用 Fast Scan 及对齐设置
- 是否确认目标值在扫描期间确实改变

## Resolution Criteria
扫描候选收敛到少量（1–10 个），且其中至少一个地址改值后目标界面实时、稳定地反映该变化；或改用代码定位方案成功找到写入指令。

## Quick Sanity Check（快速验证）
- 扫描后候选数量是否至少减少 50%？若不是，回到第 1 步重新检查数值类型。
- 改值后目标界面是否有**任何**反应？若完全无反应，说明找错地址或值被服务器控制。
- 尝试在 CE 中手动修改候选地址的值，观察是否有 1-2 个地址改值后目标有反应。

## Related Files
- `diagnostics/01-cannot-find-value.md` — 完全找不到值时的排查
- `diagnostics/10-server-side-or-protected-data.md` — 怀疑服务器控制时的判断
- `workflows/02-find-unknown-value.md` — 未知数值的查找流程
- `references/03-value-types.md` — 数值类型详解
- `references/04-scan-types.md` — 扫描类型详解
