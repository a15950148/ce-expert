# x86/x64 Assembly Essentials（汇编基础）

## 常用指令
- `mov dst, src`：把 src 复制到 dst。
- `lea dst, [addr]`：计算地址并存入 dst（不读内存，只算地址），常用于取结构体成员指针。
- `cmp a, b` / `test a, b`：比较/测试，设置标志位，本身不改变值。
- `jcc`：条件跳转，如 `je`（相等跳）、`jne`（不等跳）、`jg`/`jl`（大于/小于跳）。
- `add` / `sub`：加减。
- `imul` / `idiv`：乘除。
- `movss` / `movsd`：标量浮点移动（float / double）。
- `call`：调用函数；`ret`：返回。

## 寄存器
- x86（32 位）：EAX, EBX, ECX, EDX, ESI, EDI, ESP, EBP。
- x64（64 位）：RAX, RBX, RCX, RDX, RSI, RDI, RSP, RBP, R8–R15。
- 低 32/16/8 位复用同一寄存器：如 RAX 的低 32 位是 EAX，低 16 位是 AX，AX 高 8 位是 AH、低 8 位是 AL。

## 寻址模式
- `[reg]`：以 reg 的值为地址读内存。
- `[reg + offset]`：结构体成员访问，offset 即成员偏移。
- `[base + index*scale + disp]`：数组/对象数组访问。
- x64 下注意 **RIP 相对寻址**：`[rip + disp]` 指向相对于下一条指令的地址，写注入时需用 LEA 或 label 处理。

## 规则
- 结合周围上下文与操作数宽度解释指令，不要孤立地改某一行。
- 改数值时优先改 `mov`/`add`/`sub` 的操作数或跳转条件，而不是乱改比较逻辑。
- 注入前先记录完整指令字节（见 references/07），用于构造 AOB。
