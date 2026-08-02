-- lua-toggle.lua — 可复用的开关脚本模板
-- 用法：放在 CT 的 Lua Script 记录里，或 AA 记录用 [ENABLE]/[DISABLE] 包裹。
-- 原则：验证记录/符号后再切换，状态显式、失败上报。

-- ============================================================
-- 方式 A：通过 CT 记录开关（推荐，最稳）
-- ============================================================
local function toggleRecord(desc)
  local al = getAddressList()
  local mr = al.getMemoryRecordByDescription(desc)
  if not mr then
    showMessage("找不到记录：" .. desc)
    return false
  end
  mr.Active = not mr.Active          -- 切换勾选状态
  return mr.Active
end

-- 调用示例：按钮/热键里 toggleRecord("无限血")

-- ============================================================
-- 方式 B：直接内存读写 + 还原（适合简单数值锁定）
-- ============================================================
-- 提示：复杂注入请用 AA 记录的 [ENABLE]/[DISABLE]，本段仅作最小示例
local SYM = "player.health"          -- registerSymbol 注册的符号
local LOCK_VALUE = "9999"            -- 锁定的目标值
local original = nil                  -- 还原基准

local function enableToggle()
  local addr = getAddress(SYM)
  if addr == 0 then showMessage("地址解析失败：" .. SYM); return end
  if original == nil then
    original = readInteger(addr)      -- 首次记录原始值
  end
  writeInteger(addr, tonumber(LOCK_VALUE))
end

local function disableToggle()
  local addr = getAddress(SYM)
  if addr == 0 then return end
  if original ~= nil then
    writeInteger(addr, original)      -- 还原
    original = nil
  end
end

-- ============================================================
-- 清理：脚本停用/卸载时调用
-- ============================================================
local function cleanup()
  unregisterSymbol(SYM)               -- 若曾注册符号
  -- 关闭定时器/热键（见 lua-hotkey.lua）
end
