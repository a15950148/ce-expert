# CE Lua API

CE Lua 用于自动化、地址记录、热键、表单、定时器、内存读写与脚本控制。

## Design rules（设计规则）
- UI 逻辑与内存逻辑分离：按钮只切换记录状态，真正的读写交给记录/脚本。
- 使用符号/地址前先验证其有效性。
- 及时清理定时器、表单与事件处理器，避免残留。
- 事件或定时器足以满足时，避免 `while true` 忙轮询（会卡死 CE）。
- 失败时向用户明确上报原因。

## Core memory operations（核心内存读写）
```lua
-- 地址解析：符号名、"game.exe"+0x1234、或数字字符串均可
local addr = getAddress("player.health")        -- 符号优先
local addr2 = getAddress("game.exe"+0x4A2C10)    -- 模块+偏移

local hp = readInteger(addr)      -- 4 字节整数
local fp = readFloat(addr)        -- 单精度浮点
local db = readDouble(addr)       -- 双精度浮点
local b  = readBytes(addr, 1)     -- 单字节 (0-255)
local str = readString(addr, 16)  -- 读 16 字节字符串

writeInteger(addr, 9999)
writeFloat(addr, 100.0)
writeBytes(addr, {0x90,0x90})     -- 写入字节数组（常用于 nop）
```
- 字节序：x86/x64 为小端。读写多字节整数/浮点时无需手动转换。
- 数组读写：`readBytes(addr, n)` 返回长度为 n 的表；`writeBytes(addr, {…})` 写入。

## Address list / records（地址列表与记录）
```lua
local al = getAddressList()
local mr = al.getMemoryRecordByDescription("HP")   -- 按描述查找
-- 或 al.getMemoryRecordByID(id)
if mr then
  mr.Value = "9999"            -- 直接设值（字符串）
  mr.Active = true             -- 勾选启用
  mr.Active = false            -- 取消勾选
end

-- 新建记录
local rec = al.createMemoryRecord()
rec.setAddress("player.health")
rec.Type = vtDword             -- vtByte/vtWord/vtDword/vtQword/vtSingle/vtDouble/vtString
rec.Description = "HP"
rec.Active = true
```

## Hotkeys（热键）
```lua
-- 仅在目标动作验证完成后创建热键
local function healHotkey(sender)
  local mr = getAddressList().getMemoryRecordByDescription("HP")
  if mr then mr.Value = "9999"; showMessage("已回满血") end
end

local hk = createHotkey(healHotkey, "H")   -- 按键名，如 "H","F1","CTRL+H"
-- 清理：createHotkey 返回的对象可保存，卸载时调用 hk.destroy()
```
- 按键字符串：`"H"`, `"F1"`~`"F12"`, 组合键 `"CTRL+H"`, `"ALT+F4"`。
- 热键函数签名：`function(sender)`，`sender` 为热键对象。
- 清理时务必 `hk.destroy()`，避免重复注册。

## Forms / UI（表单界面）
```lua
local f = createForm(false)          -- false=无边框标准窗口
f.Caption = "训练器"
f.Width, f.Height = 240, 160

local btn = createButton(f)
btn.Left, btn.Top, btn.Width, btn.Height = 20, 20, 100, 24
btn.Caption = "无限血"
btn.OnClick = function()
  local mr = getAddressList().getMemoryRecordByDescription("HP")
  if mr then mr.Active = not mr.Active end
end

local lbl = createLabel(f)
lbl.Left, lbl.Top, lbl.Caption = 20, 60, "状态：就绪"
```
- 常用控件：`createButton`, `createLabel`, `createEdit`, `createCheckBox`, `createGroupBox`, `createComboBox`, `createTrackBar`, `createMemo`。
- 布局靠 `Left/Top/Width/Height` 手动定位（CE 无自动布局）。
- 关闭/清理：`f.destroy()`；长时间运行需在卸载时关闭窗体与定时器。

## Timers（定时器）
```lua
local t = createTimer(nil, false)    -- 父对象可为 nil；false=不立即启动
t.Interval = 500                      -- 毫秒
t.OnTimer = function(timer)
  -- 每 0.5s 执行一次；仅在必要时使用，避免忙轮询
  local mr = getAddressList().getMemoryRecordByDescription("HP")
  if mr then mr.Value = "9999" end
end
t.setEnabled(true)                   -- 启动
-- 清理：t.destroy()
```
- 优先用定时器/事件替代 `while true do ... end` 忙循环（会卡死 CE）。
- 减小 `Interval` 增加 CPU 占用；血量锁定 250–1000ms 足够。

## Script control（脚本控制 / Auto Assembler）
```lua
-- 用 Lua 触发一段 AA 脚本（开关类）
local aa = [[
[ENABLE]
alloc(code,512)
label(return)
code:
  mov [rax], #9999
  jmp return
"game.exe"+12345:
  jmp code
  nop
return:
[DISABLE]
"game.exe"+12345:
  db 89 01    -- 原始字节
]]
local ok, err = autoAssemble(aa)
if not ok then showMessage("注入失败："..tostring(err)) end
```
- `autoAssemble(script)` 返回 `(success, errorText)`；务必检查返回值。
- 复杂注入建议把 AA 写在 CT 的“自动汇编”记录里，由 Lua 通过 `mr.Active` 控制开关。

## Symbols（符号）
```lua
registerSymbol("player.health", addr)   -- 注册后可在 AA 中直接用名字引用
unregisterSymbol("player.health")        -- 卸载时清理，避免冲突
```
- 符号让 AA 与 Lua 共享同一命名空间，避免硬编码地址。
- 重启程序后模块基址变化，但相对偏移不变；用 `<module>+offset` 形式由 CE 自动重定位。

## Debugger hooks（调试器钩子，进阶）
```lua
debug_setBreakpoint(addr)               -- 设置软件断点
-- 在 AA 中用 debug routines 或在 Lua 中配合 onBreakpoint
function onBreakpoint()
  -- 断点命中时执行；返回 true 表示已由脚本处理（CE 不再弹窗）
  return true
end
```
- 仅在需要逐指令追踪、共享代码判别时使用（见 `workflows/11-handle-shared-code.md`）。

## Error reporting（错误上报）
```lua
local ok, err = pcall(function()
  -- 内存操作 / 表单构建
end)
if not ok then showMessage("错误："..tostring(err)) end
```
- 对可能失败的地址解析、AA 注入一律加错误检查，向用户明确报告失败原因。
