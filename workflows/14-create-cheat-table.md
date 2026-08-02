# Create Cheat Table（创建 Cheat Table）

## Goal（目标）
把多个独立功能（血量、弹药、金币、注入逻辑等）组织成一张结构清晰、可勾选、可依赖、可重启使用的 `.CT` 表。成功标准：用户打开表 → 分组清晰 → 逐条启用即生效 → 禁用即还原 → 重启游戏后稳定项仍可用。

## Prerequisites（前置）
- Correct target process attached.
- Reproducible target state.
- 各功能已在对应 workflow 中单独验证（数值/指针/注入）。
- 推荐加载 `references/13-cheat-table-design.md`。

## Procedure（步骤）
1. Establish a controlled baseline.（每条记录先确认“未启用”基准值/字节。）
2. 逐功能创建记录，按类型选择：
   - 数值锁定 → Value 或 Pointer 记录。
   - 改指令/注入 → Auto Assembler 记录，写 `[ENABLE]/[DISABLE]`。
   - 复杂开关/热键 → Lua Script 记录。
3. 用分组（Group）组织：`[Player]` / `[Weapon]` / `[World]` / `[Debug]`（见 `references/13-cheat-table-design.md`）。
4. 设置依赖（Dependencies）：注入记录依赖指针/基地址记录先启用，避免空指针。
5. 为关键记录绑定热键（记录属性 → Hotkeys），或统一在 Lua 训练器里 `createHotkey`。
6. Build the smallest working solution.（先放 2–3 条稳定项验证表可用，再逐步补全。）
7. Test enable, disable, reload, and restart behavior.（全表启用 → 逐条禁用还原 → 重启再验证稳定项。）

## Grouping example（分组示例）
```
[Player]
  ├─ 血量 (Pointer, 锁定)
  ├─ 无限血 (Auto Assembler, 注入)
  └─ 蓝/体力 (Value)
[Weapon]
  ├─ 弹药 (Pointer)
  └─ 无后坐 (Auto Assembler)
[World]
  └─ 金币 (Value)
[Debug]
  └─ 临时地址/符号（分发前删除）
```

## Decision Branches（决策分支）
- If expected evidence is absent, consult the matching file in `diagnostics/`.
- If multiple objects are affected, use object comparison and filtering.
- If the address changes, compare pointer and code-based approaches.

## Verification（验证）
- 测试：打开表 → 启用 `[Player]` 全部 → 游戏内验证；禁用逐项看还原；重启游戏启用稳定项。
- 预期：分组清晰，启用即生效，禁用即还原，稳定项重启后仍可用。
- 失败条件：某项 Disable 未还原 / 依赖顺序导致崩溃 / 重启后稳定项失效却标为稳定。
