-- lua-hotkey.lua — 可复用的热键模板
-- 用法：目标动作验证完成后才创建热键；清理时 destroy。

-- 保存句柄，便于卸载时清理
local hotkeys = {}

local function registerMyHotkey(desc, handler, key)
  -- desc: 记录描述；handler: function(sender)；key: 按键字符串
  local al = getAddressList()
  local mr = al.getMemoryRecordByDescription(desc)
  if not mr then
    showMessage("找不到记录：" .. desc)
    return nil
  end
  local hk = createHotkey(function(sender)
    -- 先做动作（这里示例：切换记录 + 上报）
    mr.Active = not mr.Active
    if handler then handler(sender, mr.Active) end
  end, key)
  table.insert(hotkeys, hk)
  return hk
end

-- 示例：按 H 回满血，按 F1 切无限弹药
registerMyHotkey("HP", function(_, on) showMessage(on and "血已锁" or "血已解锁") end, "H")
registerMyHotkey("无限弹药", nil, "F1")

-- 清理：窗体关闭/脚本停用时调用
local function clearHotkeys()
  for i, hk in ipairs(hotkeys) do
    if hk and hk.destroy then hk.destroy() end
  end
  hotkeys = {}
end
-- 注意：hotkeys 表为模块级变量，跨调用共享，避免重复注册。
