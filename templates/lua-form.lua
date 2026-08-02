-- lua-form.lua — 可复用的图形训练器模板
-- 用法：放在 CT 的 Lua Script 记录里，勾选时构建窗体，关闭时清理。
-- 原则：UI 构建与内存读写分离；关闭时销毁窗体 / 定时器 / 热键。

local f = nil
local timer = nil
local hotkeys = {}

local function toggleRecord(desc)
  local mr = getAddressList().getMemoryRecordByDescription(desc)
  if not mr then showMessage("找不到记录：" .. desc); return end
  mr.Active = not mr.Active
end

local function buildTrainer()
  if f then f.destroy(); f = nil end   -- 防止重复构建

  f = createForm(false)
  f.Caption, f.Width, f.Height = "训练器", 260, 220

  local al = getAddressList()

  -- 按钮：无限血
  local bHP = createButton(f)
  bHP.Left, bHP.Top, bHP.Width, bHP.Height = 20, 20, 120, 26
  bHP.Caption = "无限血"
  bHP.OnClick = function() toggleRecord("无限血") end

  -- 复选框：无限弹药（直接绑定记录）
  local cbAmmo = createCheckBox(f)
  cbAmmo.Left, cbAmmo.Top, cbAmmo.Caption = 20, 60, "无限弹药"
  local mrAmmo = al.getMemoryRecordByDescription("无限弹药")
  if mrAmmo then
    cbAmmo.Checked = mrAmmo.Active
    cbAmmo.OnChange = function()
      mrAmmo.Active = cbAmmo.Checked
    end
  end

  -- 标签：状态
  local lbl = createLabel(f)
  lbl.Left, lbl.Top, lbl.Caption = 20, 100, "状态：就绪"

  -- 定时器：每秒回满血（可选）
  timer = createTimer(nil, false)
  timer.Interval = 1000
  timer.OnTimer = function()
    local mr = al.getMemoryRecordByDescription("HP")
    if mr and mr.Active then mr.Value = "9999" end
  end
  timer.setEnabled(true)

  -- 关闭清理
  f.OnClose = function()
    if timer then timer.destroy(); timer = nil end
    for _, hk in ipairs(hotkeys) do if hk and hk.destroy then hk.destroy() end end
    hotkeys = {}
    f = nil
  end
end

buildTrainer()
