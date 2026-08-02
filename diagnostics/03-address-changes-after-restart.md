# Address Changes After Restart（重启后地址变化）

## Symptoms
用 `workflows/01`/`02` 找到的地址，在完全关闭并重启目标后失效（值不再变化，或指向错误数据）。

## Check Order
1. 确认是「完全退出」而非快速重启：某些目标有后台进程/反作弊残留，需彻底结束。
2. 重新找到该数值的新地址，与旧地址对比形式：
   - 旧地址是堆地址 `0x...` 且新地址不同 → 动态分配，属预期行为。
   - 旧地址是 `module+offset` 但仍失效 → 可能是 ASLR 或版本差异，检查模块基址。
3. 判断是否需要稳定方案：
   - 动态地址 → 进入 `workflows/04-pointer-scan.md`（指针）或 `workflows/06`/`07`（代码）。
   - 模块基址但失效 → 检查是否选错模块或偏移随版本变。
4. 不要硬编码绝对地址：重启即变的地址只能用指针/AOB 引用。
5. 对比已知良好基线：此前能稳定工作的脚本是否也失效，以区分「本地址特性」与「环境异常」。
6. 查阅对应 reference 与 workflow 修正方案。

## Evidence to Collect
- CE 版本
- 目标版本
- 重启前后两次的地址与数值
- 地址是否属于模块（module+offset）
- 指针/AOB 方案是否已尝试
- 脚本报错文本

## Resolution Criteria
重启后，通过指针或 AOB 重新定位到的值仍正确、可控，且多次重启一致。

## Quick Sanity Check（快速验证）
- 重启前后两个地址是否都属于堆地址（`0x...` 高位变化）？若是，属动态分配的预期行为，转指针/代码方案即可。
- 旧地址是否形如 `module+offset`？若是却仍失效，先核对模块名与当前版本偏移。
- 此前能稳定工作的脚本是否也一起失效？若是，可能是环境/版本变化，而非本地址特性。

## Related Files
- `workflows/03-find-dynamic-address.md` — 确认地址动态的流程
- `workflows/04-pointer-scan.md` — 指针扫描建立稳定引用
- `workflows/06-find-accessing-code.md` / `workflows/07-find-writing-code.md` — 代码方案替代指针
- `references/02-memory-and-process.md` — 内存与进程模型
- `references/05-pointer-analysis.md` — 指针分析原理
- `diagnostics/04-pointer-does-not-work.md` — 指针方案失效时的排查
