# Example: Lua Trainer（Lua 训练器 / 图形化修改器）

> 验证基线：CE 7.x / 64 位。文中地址、偏移、字节均为示例占位，需按实际目标替换。

## Scenario
单机本地授权训练中，希望把所有功能做成一个带按钮、复选框、热键的图形化训练器，一键控制。仅用于学习 CE Lua UI 与工程化。

## Observation
- 已有若干 CT 记录：`无限血`、`无限弹药`、`HP`（数值）、`金币`（数值）。
- 用户不想每次手动勾选，希望点按钮/按热键即可生效。

## Analysis
属于工程化场景，适用 `workflows/15-build-lua-trainer.md` + `references/12-lua-api.md`。原则：UI 逻辑与内存逻辑分离——按钮只切换 CT 记录的 `Active`，真正的内存读写由记录负责，避免重复注入与冲突。

## Implementation
1. 在 CT 表新建一条 `Lua Script` 记录，勾选时构建窗体。
2. 窗体上放"无限血""无限弹药"按钮，OnClick 里调用 `getMemoryRecordByDescription(desc).Active = not ...`。
3. 绑定热键：按 `H` 回满血、按 `F1` 切无限弹药（见 `templates/lua-hotkey.lua`）。
4. 窗体 `OnClose` 中销毁定时器/热键，避免残留（见 `templates/lua-form.lua`）。
5. 把训练器按功能分组存进 CT 表（见 `templates/cheat-table-layout.md`）。

## Verification
- 点按钮 → 对应功能启用；再点 → 关闭。
- 按热键 → 即时触发对应动作（如回血）。
- 关闭窗体 → 定时器/热键释放，内存由记录 Disable 还原。
- 重启 CE/游戏 → 重新打开训练器仍可用，无残留。
