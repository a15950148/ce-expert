# Create AOB Injection（创建 AOB 注入）

## Goal
用 AOB 定位写入/访问指令，注入自定义逻辑（如跳过扣血、固定数值、放大效果），且**重启后仍生效**。成功条件：脚本可稳定启用/禁用，重启目标后仍能解析并工作。

## Prerequisites
- 已用 `workflows/06` 或 `07` 找到目标指令并记下字节。
- 已读 `references/09-auto-assembler.md` 与 `references/10-aob-and-code-injection.md`。
- 模板参考 `templates/aa-aob-injection.txt`、`templates/aa-basic-injection.txt`。

## Procedure
1. 在 CE 地址列表右键 → 自动生成 AOB 注入脚本骨架（基于记录的指令）。
2. 检查生成的 AOB 是否唯一：模板窗口应只解析到一个地址；若多个，加长特征字节（`??` 通配易变处）。
3. 在 `[ENABLE]` 的 `code:` 段编写逻辑：
   - 保留被 `jmp` 覆盖掉的原指令（否则破坏语义）。
   - 加入自定义逻辑（如 `mov [reg], value` 强制写值，或 `nop` 跳过扣减）。
4. 在 `[DISABLE]` 段写入原始字节，确保可还原。
5. 测试：启用脚本 → 触发动作验证效果 → 禁用脚本回归原行为。
6. 重启目标，确认 AOB 仍能解析并工作。

## Decision Branches
- AOB 解析到多个地址：特征不够独特，加长或修正字节。
- 启用即崩溃：见 `diagnostics/07-injection-crashes-game.md`（检查覆盖边界、寄存器破坏、对齐）。
- 效果不对（影响了不该影响的对象）：进入 `workflows/11-handle-shared-code.md` 做对象过滤。

## Verification
- 脚本 enable/disable 可控，效果可逆。
- 重启后 AOB 重新解析成功且行为一致。
- 记录：AOB 字节、原指令、自定义逻辑、还原字节。

## Related Files
- `templates/aa-aob-injection.txt` — AOB 注入模板
- `references/09-auto-assembler.md` — Auto Assembler 语法
- `references/10-aob-and-code-injection.md` — AOB 与代码注入原理
- `diagnostics/06-aob-not-found.md` — AOB 解析失败排查
- `diagnostics/07-injection-crashes-game.md` — 注入导致崩溃排查
- `workflows/11-handle-shared-code.md` — 共享代码过滤
