# Scan Types（扫描类型）

## Exact Value（精确数值）
已知当前值时使用。先在目标里改变数值，再用新值过滤。
- 适用：金币、弹药、已知血量。
- 步骤：首次扫描当前值 → 目标里改变 → 再次扫描新值 → 重复直到结果少。

## Unknown Initial Value（未知初始值）
数值不可见或拿不到具体数字时使用。每次状态变化后用过滤器缩小范围。
- 过滤器：Increased（增大）、Decreased（减小）、Changed（变化）、Unchanged（未变）、Equal（等于某值）。
- 适用：血条、进度条、隐藏计数器。

## Changed / Unchanged（变化/未变化）
适合数值尺度未知、或值与动作强相关的情况。
- 连续多次 Unchanged 可排除噪声，连续 Changed 锁定活跃值。

## Value Between（区间）
知道大致范围时用，例如「在 0 到 100 之间」。能快速剔除大量无关结果。

## Bigger Than / Smaller Than（大于/小于）
用于只知道相对大小、不知道精确值的场景，配合多次动作收敛。

## Fuzzy Scan（模糊扫描）
内存结构未知时，按「变大了/变小了/没变」逐步逼近，不依赖具体数值。
- 与 Unknown Initial Value 配合：先 Unknown 建立基线，再用 Fuzzy 过滤。

## Pointer Scan（指针扫描）
在已找到可靠动态地址后使用。优先可复现状态，并在多次重启间验证（见 `references/05-pointer-analysis.md`）。

## 规则
保持少量受控改动。随机操作会产生噪声候选集，拖慢收敛。

## Related Files
- `references/03-value-types.md` — 数值类型选择
- `workflows/01-modify-known-value.md` — 已知数值修改流程
- `workflows/02-find-unknown-value.md` — 未知数值查找
- `diagnostics/02-too-many-results.md` — 结果不收敛的排查
- `references/05-pointer-analysis.md` — 指针扫描详解
