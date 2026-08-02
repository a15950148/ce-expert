# Example: Player-only Health（玩家专属血量 / 无限生命但敌人正常受伤）

> 验证基线：CE 7.x / 64 位。文中地址、偏移、字节均为示例占位，需按实际目标替换。

## Scenario
单机本地授权训练中，玩家受伤时希望不掉血或快速回满，但敌人仍按正常逻辑受伤、死亡。仅用于学习共享代码下的对象过滤。

## Observation
- 找到玩家血量地址（4 Bytes 或 Float），定位其写入指令 `game.exe+0x5A1B2C`。
- 让敌人也受伤，发现**同一条写入指令**同时被玩家和敌人命中 → 这是共享代码。
- 在玩家与敌人分别命中时记录对象指针：玩家 `this=rax→playerBase`，敌人 `this=rax→enemyBase`，二者不同。
- 回溯玩家对象结构，发现 `playerBase+0x08` 为 team 字段，玩家=1，敌人=2。

## Analysis
问题本质是共享代码，不能简单改写入值（否则敌人也不掉血）。正确做法是在写入指令注入，按 team/对象指针判别，仅对玩家跳过扣减或回满。属于 `workflows/11-handle-shared-code.md` + `workflows/10-identify-player-object.md`。

## Implementation
1. 用 AOB 定位写入指令，生成注入骨架。
2. 判别：读取 `[rax+0x08]`（team），`cmp` 是否为玩家值。
   ```pascal
   code:
     mov [rax+0x10], edx      // 原指令：写入新血量
     push rbx
     mov ebx, [rax+0x08]       // 读 team
     cmp ebx, 1                // 1 = 玩家
     pop rbx
     jne @skip                // 非玩家，保持原行为
     mov [rax+0x10], 9999      // 玩家：强制回满
   @skip:
     jmp return
   ```
3. `[DISABLE]` 还原原始写入字节。
4. 注意：`rax` 在此时确实指向当前对象（已多次验证）；`0x10`/`0x08` 为偏移示例，需按实际结构替换。

## Verification
- 玩家受伤：血量保持 9999，角色不掉血。
- 敌人受伤：正常扣血、可死亡，行为不变。
- 反复触发、重启目标后（AOB 重新解析）仍仅影响玩家。
