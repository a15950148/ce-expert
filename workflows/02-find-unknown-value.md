# Find Unknown Value（查找未知值：血条/进度条/隐藏计数）

## Goal
定位一个**不可见具体数字或不知道当前值**的变量（如当前血量、进度、隐藏计时器），并能稳定改写。成功条件：通过反复「变大/变小/不变」过滤，收敛到唯一地址并验证生效。

## Prerequisites
- 已附加正确目标进程。
- 能触发该数值的明确动作（受伤、恢复、移动）。
- 已读 `references/04-scan-types.md`（Unknown Initial Value / Fuzzy）。

## Procedure
1. CE 扫描类型选 Unknown Initial Value，数值类型按猜测选（血量常用 Float 或 4 Bytes）。
2. 在目标里执行一次相关动作（如受击掉血）。
3. 用过滤器：
   - 数值减小 → Decreased
   - 数值增大 → Increased
   - 不变 → Unchanged（用于排除）
   - 不确定方向但变了 → Changed
4. 重复 2–3 多次，每次配合不同动作，逐步减少候选。
5. 当候选较少时，逐个加入地址列表，改值验证哪个是真正的血量。
6. 确认后用冷冻或脚本锁定。

## Decision Branches
- 候选始终很多：换数值类型重扫（Float ↔ Double ↔ 4 Bytes）。
- 候选不减反增：检查是否选错方向，或数值被编码（如百分比）。
- 收敛后仍不确定：结合 `workflows/07-find-writing-code.md` 找写入点。

## Verification
- 改地址值后，目标血条/进度实时变化。
- 反复动作验证映射一致（掉血必对应数值下降）。
