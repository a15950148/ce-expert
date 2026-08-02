# Build Lua Trainer（构建 Lua 训练器）

## Goal（目标）
用 CE 的 Lua 表单构建一个带按钮/复选框/热键的图形化训练器，统一控制表中的各项功能，并能在关闭窗口、卸载时清理资源。成功标准：用户点按钮/按热键即触发对应功能，窗体可关闭，再次打开仍正常，无残留定时器或热键。

## Prerequisites（前置）
- Correct target process attached.
- Reproducible target state.
- 已加载 `references/12-lua-api.md`（表单/热键/定时器 API）。
- 各项功能已用 CT 记录实现（便于训练器通过 `mr.Active` 控制，而非重复注入）。

## Procedure（步骤）
1. Establish a controlled baseline.（确认每个要控制的记录已存在并验证过开关。）
2. 创建主窗体 `createForm(false)`，设置 Caption/宽高。
3. 用 `createButton` / `createCheckBox` / `createLabel` 摆放控件，`OnClick` 里改 `mr.Active` 或调用 `createHotkey` 注册的回调。
4. 把 UI 逻辑与内存逻辑分离：按钮只切 `mr.Active`，不直接写内存；内存由 CT 记录负责。
5. 如需持续锁定，用 `createTimer`（Interval 250–1000ms），不要在 `OnClick` 里写死循环。
6. Build the smallest working solution.（先做“无限血”一个按钮跑通，再加其他按钮。）
7. Test enable, disable, reload, and restart behavior.
   - 点按钮 → 功能启用；再次点 → 关闭。
   - 关闭窗体 → 定时器/热键销毁，内存由记录 Disable 还原。
   - 重启 CE/游戏 → 重新打开训练器仍可用。

## Trainer skeleton（训练器骨架）
```lua
if syntaxcheck then return end
-- 避免在语法检查时执行
local f = createForm(false)
f.Caption, f.Width, f.Height = "我的训练器", 260, 200

local al = getAddressList()

local function toggleRecord(desc)
  local mr = al.getMemoryRecordByDescription(desc)
  if not mr then showMessage("找不到记录："..desc); return end
  mr.Active = not mr.Active
  return mr.Active
end

local btnHP = createButton(f)
btnHP.Left, btnHP.Top, btnHP.Width, btnHP.Height = 20, 20, 120, 26
btnHP.Caption = "无限血"
btnHP.OnClick = function() toggleRecord("无限血") end

local btnAmmo = createButton(f)
btnAmmo.Left, btnAmmo.Top, btnAmmo.Width, btnAmmo.Height = 20, 60, 120, 26
btnAmmo.Caption = "无限弹药"
btnAmmo.OnClick = function() toggleRecord("无限弹药") end

-- 热键：按 H 回满血
local function hkHeal()
  local mr = al.getMemoryRecordByDescription("HP")
  if mr then mr.Value = "9999" end
end
local hk = createHotkey(hkHeal, "H")
```
> 清理：窗体关闭后，CE 会在会话中保留 `hk`；如需严格清理，可在窗体 `OnClose` 中 `hk.destroy()` 并 `f.destroy()`。

## Decision Branches（决策分支）
- If expected evidence is absent, consult the matching file in `diagnostics/`.
- If multiple objects are affected, use object comparison and filtering.
- If the address changes, compare pointer and code-based approaches.

## Verification（验证）
- 测试：打开训练器 → 点按钮看游戏内生效 → 再点关闭 → 关闭窗体看资源释放 → 重启 CE 再打开。
- 预期：按钮/热键生效，关闭无残留，重启可用。
- 失败条件：点按钮无反应（记录名不匹配）/ 窗体关闭后定时器仍在跑 / 报错未捕获。
