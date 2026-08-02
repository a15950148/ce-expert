# Cheat Table Layout（CT 表布局模板）

按功能域分组，稳定项与实验项隔离。详细规范见 `references/13-cheat-table-design.md`。

## 推荐结构
- **Player（玩家）**
  - Health（血量，可挂指针/锁定）
  - Stamina（体力）
  - Movement（移动速度，注入记录）
- **Weapon（武器）**
  - Ammo（弹药，禁用写入）
  - Reload（换弹，注入）
  - Recoil（后坐力，注入）
- **World（世界）**
  - Currency（金币，数值记录）
  - Time（时间，注入）
- **Debug（调试，实验性，分发前删除）**
  - Player base（玩家基址指针）
  - Object ID（对象 ID）
  - Temp addresses（临时地址）

## 记录类型选型
| 需求 | 记录类型 |
|------|----------|
| 直接读写某地址 | Value |
| 重启后仍可用 | Pointer（基地址+偏移） |
| 改指令/注入 | Auto Assembler（[ENABLE]/[DISABLE]） |
| 复杂开关/UI/热键 | Lua Script |

## 必填字段
- **Description**：清晰中文名，便于 Lua 用 `getMemoryRecordByDescription` 引用。
- **Group**：归入上述分组之一。
- **Hotkey**（关键记录）：绑定快捷键。
- **Dependency**（依赖）：注入记录依赖基址记录先启用。
- **Comment**：游戏版本 / 平台（x86/x64）/ 适用日期。

## 红线
- `[DISABLE]` 必须还原原始字节，避免游戏崩溃。
- 分发前删除 `Debug` 分组与所有临时地址。
- 让用户先"启用→禁用→重启用→重启游戏再启用"验证一遍。
