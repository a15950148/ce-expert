# Example: Shared Code Filter（共享代码过滤）

> 验证基线：CE 7.x / 64 位。文中地址、偏移、字节均为示例占位，需按实际目标替换。

## Scenario
某血量写入指令同时被玩家与敌人命中，需要只改玩家（或只改当前武器、某队），演示通用过滤框架。

## Observation
- 写入指令 `game.exe+0x...` 在玩家受伤与敌人受伤时都命中。
- 多次命中的寄存器上下文：玩家 `rax=playerBase`，敌人 `rax=enemyBase`。
- 玩家对象 `playerBase+0x08`=team 1，敌人 `enemyBase+0x08`=team 2。

## Analysis
这是共享代码过滤的典型场景。核心是「在注入点读取当前对象判别字段，仅目标分支执行自定义逻辑，其余走原行为」。属于 `workflows/11-handle-shared-code.md` + `references/11-shared-code-and-object-filtering.md`。

## Implementation
通用过滤骨架：
```pascal
code:
  mov [rax+0x10], edx        // 重放原指令（写入血量）

  // ----- 判别块 -----
  push rbx
  mov ebx, [rax+0x08]         // 读 team
  cmp ebx, 1                  // 玩家
  pop rbx
  jne @normal                // 非玩家：跳过自定义

  // ----- 自定义：仅玩家 -----
  mov [rax+0x10], 9999        // 回满

@normal:
  jmp return
```
判别量可替换为：对象指针相等 / ID 匹配 / type 匹配 / 当前武器指针相等。

## Verification
- 仅判别量匹配的对象被修改，其余完全不受影响。
- 反复触发、重启（AOB）后一致。
- 通配与边界检查见 `diagnostics/04-pointer-does-not-work.md`、`diagnostics/07-injection-crashes-game.md`。
