# Example: Health（血量 / 未知数值）

> 验证基线：CE 7.x / 64 位。文中地址、偏移、字节均为示例占位，需按实际目标替换。

## Scenario
单机本地授权训练中，希望锁定或提升血量，但不知道血量在内存里的精确数值。

## Observation
- 满血时看不到数字；受伤后血条变短，但 UI 不显示整数。
- 只知道"受伤会减少"，不知道具体存储值。

## Analysis
无法直接读数字，属于未知数值场景，适用 `workflows/02-find-unknown-value.md`：用 `Unknown initial value` 起扫，再按"减少了/没变化/增加了"反复筛选。

## Implementation
1. 选择 `Unknown initial value`（类型选 4 Bytes 或 Float，先试 4 Bytes）。
2. 挨打后选 `Decreased by`；回血时选 `Increased by`；未变化时选 `Unchanged`。
3. 反复几次后候选降到个位数，逐个加入列表改大值测试。
4. 找到血量地址后，可设"锁定"或找写入代码做免伤（见 `workflows/07-find-writing-code.md`）。

## Verification
- 改动后血条/数值按预期变化。
- 锁定后挨打不掉血（若游戏每帧回写，则需阻断写入而非只读锁定，见 `workflows/07`）。
- 重启后若地址变化，走指针或代码路径稳定化。
