# Example: Ammo（弹药 / 禁用写入）

> 验证基线：CE 7.x / 64 位。文中地址、偏移、字节均为示例占位，需按实际目标替换。

## Scenario
单机本地授权训练中，希望弹药不再减少（无限弹药），用于学习"禁用写入"技巧。

## Observation
- 开枪后弹药从 `30` → `29` → `28`，是 4 Bytes 整数。
- 找到弹药地址后，直接锁定为 `30` 有时会被游戏每帧覆盖回真实值。

## Analysis
只锁定读取值不够稳，因为游戏仍会写入递减值。更可靠的做法是让"写入弹药的指令"失效（`workflows/07-find-writing-code.md`）：找到写入代码后，用 AA 把写入指令 nop 掉，或改为写回原值。

## Implementation

> ⚠️ **先读本节末尾的「陷阱」再动手。** 下面这个"禁用写入"流程只在**写入指令经实测确认只服务于弹药**时才安全。
> 但请注意：**操作数形态只是风险信号，不是判据**——`sub [addr],1` 这类立即数直写只能说明扣减量固定，
> 不能证明这段代码只服务弹药一个对象（一个被玩家/敌人/NPC 共用的循环也可能用立即数）；`sub reg,reg` / 参数化调用
> 则提示它可能在被多个对象复用。真正的判定必须靠**运行时实测**：挂只读探针，分别触发目标行为与非目标行为，
> 比对命中的对象基址与调用点（规则见 SKILL.md 原则 6）。
> 若你还没做这步验证、且看到的是 `sub reg,reg` / 参数化调用，先**假设**它是全游戏共用的扣减函数，
> 照下面直接 NOP 会导致**子弹无伤害**——直接跳到「陷阱：命中的可能是全游戏共用的扣减函数」，那里是经两次失败后验证正确的做法。

1. 扫描已知数值 `30` → 开枪变 `29` 后扫描 → 收敛到弹药地址。
2. 对该地址 `Find out what writes to this address`，得到一条 `sub [addr],1`（或 `dec`）指令。
3. 用 AA 注入，把该写入指令替换为 nop（或用 `templates/aa-basic-injection.txt` 模板改回原值）。
   ```pascal
   [ENABLE]
   aobscanmodule(INJECT,TargetModule.exe, AA BB CC DD)
   alloc(newmem,512,INJECT)
   label(return)
   newmem:
     // 原指令：sub [rcx],1  —— 直接跳过，弹药不再减少
     jmp return
   INJECT:
     jmp newmem
     nop
   return:
   [DISABLE]
   INJECT:
     db AA BB CC DD
   dealloc(newmem)
   ```

## 陷阱：命中的可能是全游戏共用的扣减函数（实测踩坑，连错两次）

**症状**：注入后弹药确实不减少，但**子弹打出去没有伤害**。改成只 NOP 存回指令
（`mov [rdi+10],rax`）后，症状依旧。

**真正原因**：写断点命中的根本不是"弹药函数"，而是 IL2CPP 里一个**通用数值扣减辅助
函数**——弹药、体力、敌人血量全都调用它。改它 = 全游戏扣减失效 = 敌人血量也不掉 =
表现为"没伤害"。动运算错，动 store 一样错，因为**函数本身就不该动**。

先做 `find_function_boundaries` + 全函数反汇编，再下结论：

```
sub rsp,20
cmp byte ptr [静态初始化标志],00   ; IL2CPP 静态类初始化模板
mov rsi,rdx        ; ← 参数2 = 扣减数量（调用者传入）
mov rdi,rcx        ; ← 参数1 = 目标对象（调用者传入）
...
mov rbx,[rdi+10]   ; 取当前值
sub rbx,rsi        ; 当前值 - 数量
call <Max>         ; Max(0, 结果)，钳制不小于 0
mov [rdi+10],rax   ; 写回
```

即 `对象.数值 = Max(0, 对象.数值 - 扣减量)`。

### 判别"通用函数"的三个风险信号（均为信号，不是铁证，需实测确认）

1. **减数是寄存器而非立即数**：`sub rbx,rsi` 而不是 `dec rbx` / `sub rbx,1`
   → 扣多少由调用者决定，**提示**它可能被复用。但这仍是信号而非判据：某些弹药专用代码也可能用寄存器传一个固定量。
2. **目标对象来自参数**：函数开头 `mov rdi,rcx` / `mov rsi,rdx`（Win64 前两个参数）
   → 操作哪个对象也由调用者决定，**提示**为通用辅助函数。
3. **开头带 IL2CPP 静态初始化模板**：`cmp byte ptr [flag],0` + `lea rcx,[klass]` + `call`
   → 说明这是独立的托管方法，不是内联在开火逻辑里的专用代码。

命中任意一条，**不要急着 patch 这个函数本身**——先用下方"正确做法"里的只读探针实测确认它是否真的被多对象命中；
只有确认被复用（或样本不足、无法排除共享）时，才去改调用点而非函数本体。

### 正确做法：打调用点，不打被调用者

1. `find_function_boundaries` 拿到函数起止。
2. 在函数内装**只读探针**：保留全部原指令，额外把 `rdi`（对象）/ 旧值 / `rsi`（数量）/
   `[rsp+返回地址偏移]`（调用者返回地址）写进 ring buffer。游戏行为完全不变。
3. 让用户触发一次目标行为（开一枪），读 buffer → 拿到调用者返回地址。
   先读一次计数器确认空闲时调用频率为 0，可确保日志不被噪音冲掉。
4. 调用点 = 返回地址 − 5（`call rel32`）。对该处取 AOB，**把传给它的"扣减量"参数改成 0**
   （比 NOP 掉 call 更安全，见下）。这样只有弹药不扣，其它数值不受影响。

> 返回地址偏移：序言 `push rdi` + `sub rsp,20` → 函数体内 RSP 比入口低 0x28，
> 返回地址在 `[rsp+28]`；newmem 里每 `push` 一次再加 8（3 个 push + pushfq = +0x20 → `[rsp+48]`）。

**探针日志怎么读**：每条 32 字节 = `[对象][旧值][扣减量][返回地址]`。
本例开一枪抓到 5 条，旧值依次 `5 4 3 2 1`、扣减量恒为 1、返回地址全部相同
→ 确认这条调用链就是弹药，且**同一次射击序列只对应一个调用点**。
另有 1 条对象/返回地址都不同的记录，正是"共用函数"的旁证。

### 调用点改法：置 0 优于 NOP call

拿到调用点后有两种改法，优先选前者：

| 改法 | 效果 | 风险 |
|---|---|---|
| **扣减量参数置 0**（`xor edx,edx`） | 函数照常执行，`value - 0 = value` 原样写回 | 最小。setter、UI 刷新、返回值全部正常 |
| NOP 掉 `call rel32`（5 字节 `90`） | 整个扣减调用被跳过 | 若调用方使用返回值（`rax`）会拿到脏值；setter 的副作用（如 UI 通知）也一并丢失 |

Win64 调用约定下扣减量通常在 `rdx`（参数2），对象在 `rcx`（参数1）。
Hook 点选在 `call` 之前**恰好凑够 5 字节**的指令边界上，顺带把 `rcx` 存进
`alloc` 出来的 `ammoBase`，就能给 CT 加一条跨重启可用的**指针型**弹药条目：

```pascal
[ENABLE]
aobscanmodule(AMMOCALL, GameAssembly.dll, 8B C6 48 8B CF F7 D8 0F 48 C6 45 33 C0 48 63 D0 E8 ?? ?? ?? ??)
alloc(newmem,256,AMMOCALL)
alloc(ammoBase,8,AMMOCALL)
registersymbol(AMMOCALL)
registersymbol(ammoBase)
label(return)

newmem:
  mov [ammoBase],rcx     // 参数1 = 目标对象，存下来给指针条目用
  xor r8d,r8d            // 补回被覆盖的原指令
  xor edx,edx            // 参数2 = 扣减量 → 0
  jmp return

AMMOCALL+0A:             // 原 xor r8d,r8d(3) + movsxd rdx,eax(3) = 6 字节
  jmp newmem
  nop
return:

[DISABLE]
AMMOCALL+0A:
  db 45 33 C0 48 63 D0
```

> 调用点的 AOB 要带足上下文：`call` 前的参数准备序列（`neg`/`cmovs`/`movsxd` 等）
> 通常是这个调用点独有的，比 `call` 本身好用得多。`call` 的 rel32 用 `?? ?? ?? ??` 通配。

**通用原则**（修正版）：下手前先确认这段代码**只服务于目标数值**。
判断依据不是"动运算还是动 store"，而是"这段代码是不是被复用"。
被复用的函数，改哪一行都是错的——正确的入手点在它的**调用方**。

### 配套技巧：一次扫描、两处补丁

store 指令 `48 89 47 10` 这种字节极其常见（本例在模块内重复 30 次，加上下文
仍有 3 处），无法单独定位。而运算处的特征码往往唯一。做法是**用唯一特征码做锚点，
按偏移访问 store**：

```
aobscanmodule(AOBBASE, GameAssembly.dll, 48 2B DE 45 33 C0 48 8B D3 33 C9 E8 ?? ?? ?? ??)
registersymbol(AOBBASE)

AOBBASE+1A:
  db 90 90 90 90        // store 距锚点 +0x1A

[DISABLE]
AOBBASE+1A:
  db 48 89 47 10
```

CE AA 支持 `symbol+offset:` 作为地址表达式，无需额外 define。偏移要按指令长度
逐条累加算准，别用地址相减以外的方式估。

## Verification
- 开枪后弹药数保持不变（或锁定值不被覆盖）。
- 换弹、拾取弹药等行为正常，无崩溃。
- 禁用注入后弹药恢复递减；重启游戏（AOB 重新解析）仍有效。

## 实测案例：Unity IL2CPP（x64 / GameAssembly.dll）

> 真实完成并验证过的一例，可作为 IL2CPP 类游戏的参照。

**特征**：进程加载 `UnityPlayer.dll` + `GameAssembly.dll` → 判定为 IL2CPP，写入代码落在 `GameAssembly.dll`，地址随重启变化，必须走 AOB。

**代码现场**（写入弹药不是简单的 `sub [addr],1`，而是「取出 → 算 → 调 setter → 写回」四段式）：
```
mov rbx,[rdi+10]     ; 取当前弹药（rdi = 武器结构体基址）
...
sub rbx,rsi          ; ← 递减（rsi = -1）  ★ 真正要跳过的指令
xor r8d,r8d
mov rdx,rbx
xor ecx,ecx
call <setter>
mov [rdi+10],rax     ; ← store（写断点命中报的是它之后的指令）
```

**关键判断（已被实测推翻，保留作反面教材）**：当时以为"跳过 `sub` 比 NOP store 更精准"。
错。这段代码是全游戏共用的扣减辅助函数（`sub rbx,rsi` 的减数来自参数 `rsi`，对象来自参数 `rdi`），
两种改法都会让敌人血量同样不掉，表现为**子弹没伤害**。正确入手点见上文
「陷阱：命中的可能是全游戏共用的扣减函数」——去打**调用点**。

**AOB 选取**：`sub rbx,rsi` 的字节 `48 2B DE` 极其常见，必须带上下文。取 `48 2B DE 45 33 C0 48 8B D3 33 C9 E8 ?? ?? ?? ??`（sub + xor + mov + xor + call，call 相对地址通配），`aob_scan_module_unique` 确认模块内唯一后才注入。

**字节对齐**：`jmp newmem` 占 5 字节，会连带覆盖 `sub`(3) 后面的 `xor r8d,r8d`(3) 的第一字节，所以补 1 个 `nop` 凑满 6 字节到指令边界，并在 newmem 里**补回 `xor r8d,r8d`**，再 `jmp return` 落到 `mov rdx,rbx`：
```pascal
newmem:
  xor r8d,r8d        // 补回被 jmp 覆盖的指令
  jmp return
INJECT:
  jmp newmem
  nop                // 补齐到 6 字节指令边界
return:
```
注入后 `read_memory(INJECT, 6)` 应读到 `E9 xx xx xx xx 90`。
