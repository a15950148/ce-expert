# Quick Lookup（速查索引）

> 排错总入口。原「常见错误」与「症状速查」两张表在 `SKILL.md` 内联，
> 为控制入口体积合并下沉至此。按现象直接定位，不必逐条比对场景表。

## 按症状定位

| 现象 | 文件 |
|---|---|
| 扫不到任何地址 | `diagnostics/01-cannot-find-value.md` |
| 扫得到但候选不收敛 | `diagnostics/02-too-many-results.md` |
| 重启后地址失效 | `diagnostics/03-address-changes-after-restart.md` |
| 指针解析错误或间歇失效 | `diagnostics/04-pointer-does-not-work.md` |
| 断点 / Find what accesses(writes) 不命中 | `diagnostics/05-breakpoint-does-not-trigger.md` |
| `aobscan` 报找不到 | `diagnostics/06-aob-not-found.md` |
| 启用脚本即崩溃 / 触发动作时崩溃 | `diagnostics/07-injection-crashes-game.md` |
| 脚本启用报错、自动取消勾选 | `diagnostics/08-script-enable-failed.md` |
| 改值后敌人 / NPC 也被影响 | `diagnostics/09-shared-code-affects-all-entities.md` |
| 改不动 / 被回滚 / 怀疑服务器或反作弊 | `diagnostics/10-server-side-or-protected-data.md` |
| MCP 工具报错、连接异常、Bridge 行为怪异 | `mcp/troubleshooting.md` |

## 按错误原因定位

| 错误 | 后果 | 去哪 |
|---|---|---|
| 扫描类型选错（Exact vs Fuzzy） | 找不到值或结果不收敛 | `references/04-scan-types.md` |
| 数值类型不匹配（整数 vs 浮点） | 扫描失败 | `references/03-value-types.md` |
| 未验证 AOB 唯一性 | 注入到错误地址，游戏崩溃 | `workflows/12-create-aob-injection.md` |
| **AOB 特征码包含了自身要覆盖的字节** | 补丁打上后无法再次勾选，必须重启游戏 | `references/17-script-quality.md` |
| 注入后未重放原指令 | 游戏逻辑缺失，崩溃 | `templates/aa-aob-injection.txt` |
| 硬编码绝对地址 | 重启后失效 | `workflows/03-find-dynamic-address.md` |
| **未验证对象范围就改共享代码** | 影响所有对象（敌人也无敌 / 打不出伤害） | `SKILL.md` 原则 6 + `workflows/11-handle-shared-code.md` |
| 修改的值还有下游消费者（被传入后续 call） | 数值锁住了但行为异常（如子弹无伤害） | `references/17-script-quality.md` |
| 未测试 enable→disable→enable | 脚本不稳定、无法还原 | `diagnostics/07-injection-crashes-game.md` |
| 外部工具直接写内存后未还原 | 用户加载 CT 时 AOB 扫不到 | `mcp/troubleshooting.md` |

## 三条最常见的误判

1. **「值锁住了 = 成功」** —— 还要验证行为正常（伤害、UI、拾取、换弹）。
   数值正确但行为异常，通常说明改的那个值有下游消费者。
2. **「只有一个对象命中 = 单对象」** —— 样本不足。必须主动触发非目标行为
   （打敌人、让敌人开火）再比对。
3. **「重启后失效 = AOB 写错了」** —— 先确认是否为特征码自遮挡（见上表），
   以及补丁是否被外部工具打进内存而 CE 表并不知情。
