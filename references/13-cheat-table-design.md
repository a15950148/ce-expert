# Cheat Table Design

## Recommended organization（推荐组织方式）
Player → health/stamina/movement
Weapon → ammo/reload/recoil
World → time/currency
Debug → addresses/IDs

## Rules
Use clear descriptions, groups, dependencies, hotkeys, and notes about game version. Keep experimental entries separate from stable entries.

## Record types（记录类型）
CE 表中每条记录可设置为以下类型之一：
- **Value（数值）**：直接读取/写入某地址（或指针链）的值。
- **Pointer（指针）**：保存基地址+多级偏移，重启后仍能解析（见 `references/05-pointer-analysis.md`）。
- **Auto Assembler（自动汇编）**：存放 `[ENABLE]/[DISABLE]` 注入脚本，由勾选状态控制开关。
- **Lua Script（Lua 脚本）**：在勾选/取消时执行 Lua，用于复杂开关、热键、UI。

## Grouping（分组）
- 用分组（Group）承载上述四类，对应 Player / Weapon / World / Debug。
- 分组也可嵌套，形成树状结构；每组建议加版本备注（`Comment` 字段）。
- 命名示例：`[Player] 血量`、`[Weapon] 弹药`、`[World] 金币`、`[Debug] 地址`。

## Dependencies（依赖）
- 勾选一条记录时，可设置它依赖其他记录先启用（Dependency），保证加载顺序。
- 例：注入逻辑记录依赖“基地址已解析”记录，避免空指针崩溃。
- 在记录属性 → Advanced → Dependencies 中选择依赖项。

## Hotkeys（热键）
- 为关键记录绑定热键（记录属性 → Hotkeys）。
- 支持“设为值”“切换激活”“运行 Lua”三类动作。
- 训练器型热键（回血、刷钱）建议放 Lua 记录里用 `createHotkey` 统一管理（见 `workflows/15-build-lua-trainer.md`）。

## Stability classification（稳定性分类）
- **稳定（Stable）**：经重启 + 多次使用验证通过，相对偏移/指针/AOB 稳定。
- **实验（Experimental）**：仅当前会话有效、或依赖手动定位，放入 `[Debug]` 分组，与稳定项隔离。
- 分发前删除 `[Debug]` 分组中的临时地址，避免用户误用失效条目。

## Version notes（版本备注）
- 每条关键记录或分组写明 `Comment`：游戏版本、扫描日期、适用平台（x86/x64）。
- 游戏更新后基址常变；备注让用户快速判断是否需要重新定位。

## Symbols and scripts（符号与脚本）
- 复杂方案里用 `registerSymbol` 注册关键地址（见 `references/12-lua-api.md`），AA 直接引用符号名，便于维护。
- 把注入脚本写成 AA 记录而非纯 Lua，让 CT 表自带、可勾选、可依赖，分发更可靠。

## Saving & sharing（保存与分发）
- 保存为 `.CT` 文件；表中内嵌的 Lua 脚本会一并保存。
- 分发前：删除个人路径、临时地址、调试分组；确认 Enable/Disable 字节正确。
- 让用户先“启用 → 禁用 → 重新启用 → 重启游戏再启用”验证一遍。

## Checklist before distribution（分发前检查单）
- [ ] 所有记录描述清晰、分组合理
- [ ] 启用/禁用字节正确，Disable 还原原始指令
- [ ] 指针/偏移/AOB 经重启验证
- [ ] 实验项与稳定项隔离
- [ ] 版本/平台备注完整
- [ ] 用户在自己的环境验证通过
