# Script Enable Failed（脚本启用报错）

## Symptoms
在 CT 表勾选启用 Auto Assembler 脚本时，CE 弹出错误提示（如 "Failure converting..."、未定义符号、地址无法解析），脚本无法启用，或启用后立即自动取消勾选。

## Check Order
1. 阅读完整报错文本：CE 的错误信息会指出具体行号/符号/地址，是定位根因的第一手线索。先抄录全文。
2. 检查语法：
   - `[ENABLE]`/`[DISABLE]` 段标记是否成对存在。
   - 每条指令、`alloc`/`dealloc`/`label`/`registersymbol` 拼写正确。
   - 注释 `//` 或 `{}` 未破坏指令行。
3. 检查标签与符号定义：
   - `label(return)` 之类的标签必须先声明再用。
   - 跳转目标、`code:` 段名必须存在；`jmp return` 中的 `return` 若未定义会报错。
   - `registersymbol` 与 `unregistersymbol` 配对（见 `references/12-lua-api.md`）。
4. 检查 `alloc`：分配内存语句格式 `alloc(name, size, [near])`；若指定 `near` 但目标地址无法解析，分配会失败。
5. 检查地址解析：
   - `"game.exe"+0x1234` 中模块名是否正确加载、偏移是否当前版本有效。
   - AOB 是否解析成功（若失败见 `diagnostics/06-aob-not-found.md`）。
   - 绝对地址在重启后失效，应改用模块+偏移或 AOB（见 `references/02-memory-and-process.md`）。
6. 检查 DISABLE 段：还原字节 `db ...` 是否与原始字节一致；若 ENABLE 实际未成功注入，DISABLE 还原也会失败。
7. 检查 32/64 位：64 位下需用 64 位寄存器（`rax` 而非 `eax` 视指令而定）、注意 `jmp` 的距离（远跳用 `jmp far` 或分配近内存）。
8. 最小化定位：复制脚本，只保留原指令重放 + 跳回（空注入），确认能启用，再逐步加自定义逻辑定位出错行。

## Evidence to Collect
- CE 版本与目标版本（32/64 位）
- 完整脚本文本（含 ENABLE/DISABLE）
- CE 报错全文（含行号/符号）
- 模块名与偏移
- 是否能启用空注入版本

## Resolution Criteria
脚本可稳定启用且无报错，效果符合预期，并能 enable → disable → enable 多次反复；DISABLE 还原后目标行为回归正常。

## Quick Sanity Check（快速验证）
- CE 报错文本是否指向具体行号/符号？先抄录全文，按行号定位而非盲目修改。
- `[ENABLE]`/`[DISABLE]` 是否成对、`label`/`registersymbol` 是否先声明再用？
- 复制脚本只保留「原指令重放 + 跳回」能否启用？能=问题在自定义逻辑；不能=语法/地址解析问题。

## Related Files
- `workflows/12-create-aob-injection.md` — AOB 注入创建流程
- `references/09-auto-assembler.md` — Auto Assembler 语法
- `references/12-lua-api.md` — Lua API（符号注册/AA 调用）
- `templates/aa-aob-injection.txt` — AOB 注入模板
- `diagnostics/06-aob-not-found.md` — AOB 解析失败排查
- `diagnostics/07-injection-crashes-game.md` — 启用后崩溃排查
