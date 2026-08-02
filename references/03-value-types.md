# Value Types（数值类型）

| 类型 | 典型大小 | 常见用途 |
|---|---:|---|
| Byte | 1 字节 | 标志位、小计数器、布尔 |
| 2 Bytes / Word | 2 字节 | 紧凑整数、状态枚举 |
| 4 Bytes / Dword | 4 字节 | 最常见的整数类型 |
| 8 Bytes / Qword | 8 字节 | 64 位整数、指针 |
| Float | 4 字节 | 常见小数（血量、坐标） |
| Double | 8 字节 | 高精度小数（物理、时间） |
| String | 变长 | 文本、名称、ID |
| Array of byte (AOB) | 变长 | 指令字节、特征码 |

## 选择类型的判断方法
- 显示的整数，内部可能存为 Float 或 Double。不要只看外观，要测试行为。
- 血量、坐标、速度等带小数的值，优先尝试 Float；精度异常时试 Double。
- 计数器、等级、数量通常是 4 Bytes 整数。
- 指针和地址本身就是 4 Bytes（32 位进程）或 8 Bytes（64 位进程）。

## 常见陷阱
- **显示 100，扫描 4 Bytes 找不到**：尝试 Float，或值被编码（如乘以 10 存 1000）。
- **Float 显示为整型**：游戏可能用 Float 存储 100.0，扫描精确值 100 会失败，应扫描 100 或 100.0。
- **字节序**：x86/x64 为小端序，内存中低位在前；CE 默认按小端解析，通常无需手动处理。
- **对齐访问**：某些指令要求内存地址对齐（如 SSE 指令），未对齐会崩溃（见 `diagnostics/07-injection-crashes-game.md`）。

## 与扫描的衔接
不确定时用 `references/04-scan-types.md` 的「未知初始值」或「模糊扫描」逐步收敛。

## Related Files
- `references/04-scan-types.md` — 扫描类型选择
- `workflows/01-modify-known-value.md` — 已知数值修改流程
- `workflows/02-find-unknown-value.md` — 未知数值查找
- `diagnostics/01-cannot-find-value.md` — 找不到值时的排查
- `diagnostics/02-too-many-results.md` — 结果不收敛的排查
