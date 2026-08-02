# Shared Code Affects All Entities（共享代码误伤多个对象）

## Symptoms
注入或改值后，本意只影响玩家，结果敌人/NPC 也被同样影响（玩家无敌时敌人也无敌、玩家攻击力提升时敌人也提升）。

## Check Order
1. 确认代码共享：用 "Find what accesses/writes" 该地址，观察命中指令是否在玩家和敌人动作时都被触发。若同一指令服务多对象，即为共享代码（见 `references/11-shared-code-and-object-filtering.md`）。
2. 分析寄存器上下文：命中时查看 `RAX`/`RCX`/`RDX`/`RDI` 等寄存器，找出指向"当前对象"的基址寄存器。玩家对象与敌人对象的基址不同，可用此区分。
3. 找判别条件：在玩家 vs 敌人两种状态下分别记录寄存器与对象内存，找出唯一标识玩家的字段（如对象体内某偏移的 type/id、是否为本地玩家指针、与某个全局基址相等）。
4. 加对象过滤：在注入代码里 `cmp` 判别字段，只有玩家时才执行修改，否则直接走原指令（见 `workflows/11-handle-shared-code.md`、`templates/aa-register-filter.txt`）。
5. 确认过滤条件稳定：判别字段不能是动态分配的临时值，应在玩家对象生命周期内恒定；用多场景（切换角色、重生、换关卡）验证。
6. 排除过滤过严/过松：
   - 过严：玩家也不生效，说明判别条件选错或寄存器假设错误。
   - 过松：敌人仍被影响，说明判别条件未区分开，需换字段或增加组合条件。
7. 避免 ID 硬编码：若用对象 ID，注意 ID 可能随关卡/版本变化；优先用结构上的稳定特征（如本地玩家指针比较）。

## Evidence to Collect
- CE 版本与目标版本（32/64 位）
- 共享指令的字节与所在模块
- 玩家/敌人两种状态下命中时的寄存器值
- 玩家对象的稳定判别字段及偏移
- 过滤脚本文本（含 cmp 与跳转）
- 多场景测试结果（不同敌人、重生、换关卡）

## Resolution Criteria
注入脚本仅影响玩家对象，敌人/NPC 行为不受影响；且在切换角色、重生、换关卡等场景下过滤仍然成立。

## Quick Sanity Check（快速验证）
- 用 "Find what accesses/writes" 该地址，玩家与敌人触发时是否命中**同一条**指令？若是，即为共享代码。
- 命中时哪个寄存器指向当前对象基址？玩家与敌人该寄存器值是否不同？
- 过滤后玩家是否生效、敌人是否不受影响？两者都满足才算判别量选对。

## Related Files
- `workflows/11-handle-shared-code.md` — 共享代码处理流程
- `workflows/09-analyze-data-structure.md` — 数据结构分析找判别字段
- `workflows/10-identify-player-object.md` — 识别玩家对象
- `references/11-shared-code-and-object-filtering.md` — 共享代码与对象过滤原理
- `templates/aa-register-filter.txt` — 寄存器过滤模板
