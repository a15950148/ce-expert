# Example: Experience（经验 / 未知增长值）

> 验证基线：CE 7.x / 64 位。文中地址、偏移、字节均为示例占位，需按实际目标替换。

## Scenario
单机本地授权训练中，希望快速获得经验值，用于学习"增长型未知值"的查找。

## Observation
- 升级后经验从 `0` 开始，击败敌人后增加 `120`，但平时看不到确切数值。
- 只知道"击杀后会增加"，数值单调递增。

## Analysis
属于未知数值，但比纯未知多了"会增加"的线索，适用 `workflows/02-find-unknown-value.md`：起扫 `Unknown initial value`，击杀后选 `Increased by`，平时选 `Unchanged`，快速收敛。

## Implementation
1. 起扫 `Unknown initial value`（4 Bytes 或 Float）。
2. 击杀一个敌人后选 `Increased by`；未击杀时反复选 `Unchanged` 排除无关地址。
3. 候选收敛后，逐个改大值（如 `9999999`）测试经验条/等级是否变化。
4. 找到经验地址后，可改为"写入时 +N"实现刷经验，或锁定为极大值。

## Verification
- 修改后经验/等级按预期变化，触发升级无异常。
- 注意经验常驱动等级、属性等派生数据；若改经验无效，去查"等级字段"或写入经验的那条指令（`workflows/07`）。
- 重启后地址变化则走指针/代码路径稳定化。
