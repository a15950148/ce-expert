# Example: AOB Injection（基础 AOB 注入）

> 验证基线：CE 7.x / 64 位。文中地址、偏移、字节均为示例占位，需按实际目标替换。

## Scenario
单机本地授权训练中，某数值由一段编译后固定、但地址随重启变化的指令写入，需要用 AOB 注入做到重启仍生效。

## Observation
- 找到写入指令 `48 89 0A`（类 `mov [rdx], rcx`），地址每次重启都变。
- 该指令在 `game.exe` 模块内，周围字节可构成稳定 AOB。

## Analysis
地址动态，不能硬编码。用 `aobscan` 按字节特征定位符号 `inj`，再用 `alloc` 做 code cave 注入。属于 `workflows/12-create-aob-injection.md` + `references/10-aob-and-code-injection.md`。

## Implementation
```pascal
[ENABLE]
// 1. 记录原始字节：启用前用 readBytes 或 Memory View 抄录 inj 处的精确字节，供 DISABLE 还原
aobscan(inj, 48 89 0A ?? ?? 55 48 83 EC 20)
alloc(code, 4096)
label(return)

code:
  mov [rdx], rcx        // 重放原指令（被 jmp 覆盖掉的指令必须在这里补跑）
  // 自定义逻辑写在此处
  jmp return

inj:
  jmp code
  nop
return:

[DISABLE]
// 2. 还原原始字节：db 只接受具体字节数值，不能用通配符 ??
//    把下面替换为启用前抄录的精确原始字节（通配位 ?? 必须填回真实字节）
inj:
  db 48 89 0A 90 90 55 48 83 EC 20   // 示例：原通配位此处假设为 90 90，请按实际抄录
dealloc(code)
```
- 用 `??` 通配易变字节（仅 `aobscan` 模式串内合法），确保解析唯一。
- 原指令在 code cave 重放，避免逻辑缺失。
- **DISABLE 还原字节必须是与 ENABLE 前完全一致的具体字节**：`??` 仅在 `aobscan` 模式串里合法，`db` 指令不接受通配符。启用前用 `readBytes(inj, 长度)` 或 Memory View 抄录原始字节备用。
- 参考 `templates/aa-aob-injection.txt`、`templates/aa-basic-injection.txt`。

## 陷阱：特征码不可包含自己要覆盖的字节（实测确认）

**症状**：补丁已经打上的状态下，重新加载脚本 / 重新勾选条目会失败，
勾选自动弹回或报 `not all results found`，**必须重启游戏才能再次勾选**。

**原因**：`aobscanmodule` 的模式串里包含了 hook 要改写的那几个字节。
补丁一旦写入，这段字节变成 `E9 xx xx xx xx 90`，特征码就永远匹配不上了：

```
8B C6 48 8B CF F7 D8 0F 48 C6 [45 33 C0 48 63 D0] E8 ?? ?? ?? ??
                               ^^^^^^^^^^^^^^^^^^
                               hook 打上后 -> E9 xx xx xx xx 90
```

`[ENABLE]` 第一句扫描失败 → 整段脚本失败 → CE 把勾弹回。
重启游戏后内存从磁盘重新映射、原始字节恢复，才又能扫到 —— 这就是
"必须重启一次游戏才能勾选"的全部原因。

**修正：把被覆盖的字节通配掉，让特征码只依赖 hook 区域之外的字节。**

```
aobscanmodule(AMMOCALL, GameAssembly.dll, 8B C6 48 8B CF F7 D8 0F 48 C6 ?? ?? ?? ?? ?? ?? E8 ?? ?? ?? ??)
```

改完实测：**补丁存在时扫描依然唯一命中**，可随时勾选 / 取消 / 重载脚本。

**原则**：
1. 优先把扫描锚点选在 hook 区域**之外**（前面或后面的稳定字节），
   用 `符号+偏移` 访问真正的 patch 点 —— 本例即 `AMMOCALL+0A`。
2. 无法避开时，把要覆盖的 N 个字节全部写成 `??`，保证脚本**幂等**。
3. 通配后必须重新验证唯一性（确定字节变少，可能不再唯一）；
   不唯一就往两侧扩展上下文，而不是把通配改回具体字节。
4. `[DISABLE]` 段的 `db` 仍写**具体原始字节**（`db` 不接受 `??`），
   所以启用前务必抄录原字节。

> 上文 Implementation 的示例 `aobscan(inj, 48 89 0A ?? ?? 55 48 83 EC 20)` 就是
> 反例：`inj` 处 6 字节会被 `jmp`+`nop` 覆盖，而特征码前 6 字节正是它们。
> 实际使用时应改为 `?? ?? ?? ?? ?? ?? 55 48 83 EC 20` 并重新验证唯一性。

**另一种触发同样症状的情形**：补丁是被外部工具（如 CE MCP Bridge 的
`auto_assemble`）直接写进内存的，CE 的 CT 表并不知道它存在 ——
表里条目仍是未勾选状态，取消勾选也还原不了。交付前必须
`write_memory` 写回原字节，并用 `aob_scan_module_unique` 确认能重新命中。

## Verification
- 脚本 enable/disable 可逆，效果稳定。
- 重启目标后 AOB 重新解析成功，行为一致。
- **补丁已启用的状态下再次执行 `[ENABLE]` 仍能扫到目标**（幂等性检查）。
