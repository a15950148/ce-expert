# Create Toggle Script（创建开关脚本）

## Goal（目标）
让某功能（如无限血、无限弹药）能用一次勾选/取消来启用和关闭，并在禁用时完整还原原始状态。成功标准：勾选生效、取消还原、重新勾选仍生效、重启游戏仍可定位（若用指针/AOB）。

## Prerequisites（前置）
- Correct target process attached.（已附加正确目标进程。）
- Reproducible target state.（目标状态可复现。）
- Relevant references loaded from `references/`。（已加载相关参考：推荐 `references/12-lua-api.md`、对应 workflow 的注入/`references/10-aob-and-code-injection.md`。）
- 已确认目标地址/指针/AOB 唯一且稳定。

## Procedure（步骤）
1. Establish a controlled baseline.（先记录“未启用”时的原始值/原始字节作为还原基准。）
2. 用 Lua 或 AA 实现“启用”逻辑；优先改造为可开关形式：
   - 简单数值锁定 → 用数值记录 + 勾选（无需 Lua）。
   - 改指令/注入 → 用 AA 记录，写 `[ENABLE]` 与 `[DISABLE]`，Disable 还原原始字节。
3. 在 `[DISABLE]` 段落明确还原：写回原始字节、解除符号、关闭定时器/热键。
4. Build the smallest working solution.（先用最小脚本验证开关有效，再加 UI/热键。）
5. 若需热键或 UI，在 Lua 脚本里通过 `createHotkey` / 修改 `mr.Active` 控制，而非重复注入。
6. Test enable, disable, reload, and restart behavior.
   - 启用 → 观察效果。
   - 禁用 → 确认数值/代码回到基准。
   - 再启用 → 仍生效。
   - 重启游戏 → 若用指针/`module+offset`，确认仍能解析。

## Toggle via Lua record（Lua 记录开关模板）
```lua
-- 放在 CT 的 Lua Script 记录里，勾选时执行
if syntaxcheck then return end
-- ENABLE 段：由 record.Active 触发
[ENABLE]
local al = getAddressList()
local mr = al.getMemoryRecordByDescription("无限血")
if mr then mr.Active = true end

[DISABLE]
local al = getAddressList()
local mr = al.getMemoryRecordByDescription("无限血")
if mr then mr.Active = false end
```
> 说明：CE 的 Lua Script 记录不支持 `[ENABLE]/[DISABLE]` 语法，上述写法仅示例意图。实际做法是：在记录属性里分别填“激活时脚本”与“停用脚本”，或在 AA 记录里实现开关。Lua 记录更常用于注册热键/表单，开关逻辑交给数值/AA 记录。

## Decision Branches（决策分支）
- If expected evidence is absent, consult the matching file in `diagnostics/`.（看不到效果 → 查 diagnostics/01-cannot-find-value 等。）
- If multiple objects are affected, use object comparison and filtering.（影响多个对象 → 见 `workflows/11-handle-shared-code.md`。）
- If the address changes, compare pointer and code-based approaches.（地址变化 → 用指针或 `module+offset`，见 `workflows/03-find-dynamic-address.md`。）

## Verification（验证）
Document the exact test, expected result, and failure condition.
- 测试：勾选开关 → 游戏内行为；取消 → 行为恢复；重启游戏再勾选。
- 预期：启用即生效，禁用即还原，重启后仍可定位。
- 失败条件：禁用后行为未还原 / 重启后失效且未用稳定定位方式 / 报错未捕获。
