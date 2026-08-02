# AOB Not Found（AOB 解析失败）

## Symptoms
`aobscan` / `aobscanmodule` 在启用脚本时找不到匹配地址（报 "could not be found"），或解析到的地址数量为 0，脚本无法启用。

## Check Order
1. 核对字节抄录：重新打开 Memory View，对照指令的字节是否抄错（漏字节、顺序错、十六进制写错）。手抄字节是最常见错误来源。
2. 确认目标版本一致：游戏更新后指令字节/布局会变，旧 AOB 在新版本上必然失效。核对当前目标版本与 AOB 来源版本。
3. 检查模块名：`aobscanmodule` 的模块名必须与实际加载的模块名完全匹配（含大小写、`.exe`/`.dll` 后缀）。用 Memory View → View → Enumerate DLL's 确认模块名。
4. 调整通配符：
   - 通配过窄（全是固定字节）：易因版本/重定位差异失败，可对易变字节（重定位项、地址偏移）用 `??`。
   - 通配过宽（太多 `??`）：可能解析到 0 个或多个错误地址。在唯一性与稳定性间取平衡（见 `workflows/12-create-aob-injection.md`）。
5. 确认扫描范围：`aobscan` 全进程扫描；`aobscanmodule` 限定模块。若指令在动态分配内存而非模块内，`aobscanmodule` 会找不到，改用 `aobscan` 或先定位所属模块。
6. 验证 AOB 唯一性：在 CE 的 AOB 模板窗口手动搜索该特征，确认解析到的地址数量；若为 0 则字节或范围有误，若 >1 则需加长特征。
7. 区分 32/64 位：同一段逻辑在 32/64 位下指令字节不同（如 `mov` 的 RIP 相对寻址），AOB 不可跨架构混用。

## Evidence to Collect
- CE 版本与目标版本（32/64 位）
- AOB 字节串（含通配符位置）
- 使用的扫描方式（`aobscan` vs `aobscanmodule`）与模块名
- CE AOB 搜索窗口手动搜索的命中数量
- 指令所在内存区域（模块内 / 动态分配）

## Resolution Criteria
`aobscan`/`aobscanmodule` 在启用时解析到且仅解析到一个地址，脚本成功启用并注入，且重启目标后仍能稳定解析。

## Quick Sanity Check（快速验证）
- 在 CE 的 AOB 模板窗口手动搜索该特征串，命中数是 0 还是 >1？0=字节/范围错，>1=特征不够独特需加长。
- 通配符是否误用了半字节形式（如 `5?`）？CE 仅支持整字节 `??`。
- `aobscanmodule` 的模块名是否与 Memory View → Enumerate DLL's 列出的完全一致（含大小写与后缀）？

## Related Files
- `workflows/12-create-aob-injection.md` — AOB 注入创建流程
- `references/10-aob-and-code-injection.md` — AOB 与代码注入原理
- `references/09-auto-assembler.md` — Auto Assembler 语法
- `templates/aa-aob-injection.txt` — AOB 注入模板
- `diagnostics/08-script-enable-failed.md` — 脚本启用报错排查
