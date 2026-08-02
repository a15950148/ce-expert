# Pointer Does Not Work（指针失效）

## Symptoms
生成的指针在重启后解析到错误地址、值不再变化，或偶尔有效偶尔失效。

## Check Order
1. 确认指针在**生成时**确实指向正确值（先验证再重启）。
2. 检查基址来源：优先 `module+offset` 形式的模块基址；若基址本身来自堆，则整条链都不稳。
3. 检查层数：层数越多越脆弱，跨场景/跨地图可能失效。优先选层级少、重启多次仍唯一的指针。
4. 重新做「重启 → 重新找地址 → 重新扫描」至少两轮，确认指针在多次重启中都成立（见 `workflows/04-pointer-scan.md`）。
5. 检查是否在错误的游戏状态扫描：例如在某关卡内找到的指针，回到主菜单就失效。应在目标稳态（如实战中）验证。
6. 若多次重启无指针存活：放弃指针，改用 `workflows/06`/`07` 代码方案（更稳）。
7. 查阅 `references/05-pointer-analysis.md` 理解基址/偏移/层数。

## Evidence to Collect
- CE 版本
- 目标版本
- 指针的基址、各级偏移、层数
- 每次重启后解析到的地址与值
- 验证时所处游戏状态

## Resolution Criteria
至少两次独立重启后，指针解析地址正确、数值可控；记录验证的重启次数与游戏状态。

## Quick Sanity Check（快速验证）
- 指针基址是否来自模块（`module+offset`）？若基址本身在堆上，整条链都不稳，需重新选基址。
- 层数是否过多（>6）？层数越多越脆弱，优先选层数少且重启多次仍唯一的指针。
- 验证时是否在目标稳态（实战中）而非过渡态（加载/换关卡）？过渡态找到的指针易失效。

## Related Files
- `workflows/04-pointer-scan.md` — 指针扫描流程
- `workflows/03-find-dynamic-address.md` — 确认地址动态
- `workflows/06-find-accessing-code.md` / `workflows/07-find-writing-code.md` — 指针失效时改用代码方案
- `references/05-pointer-analysis.md` — 指针分析原理
- `diagnostics/03-address-changes-after-restart.md` — 重启后地址变化的排查
