# Auto Assembler（自动汇编）

Auto Assembler (AA) 是 CE 用于编写内存修改、代码注入、Lua 混合脚本的语言。Cheat Table 里的脚本都用 AA 编写。

## 典型区块
```
[ENABLE]
// 启用逻辑：分配内存、定义标签、注入跳转、执行逻辑

[DISABLE]
// 还原逻辑：恢复原始指令与字节、释放资源
```

## 常用语法
- `alloc(name, size)`：分配可执行内存（code cave），size 通常 4096 起步。
- `label(lbl)`：声明本地标签，供跳转引用。
- `registersymbol(name)`：把符号注册为全局，供其他脚本或 Lua 引用。
- `aobscan(name, AOBpattern)`：按字节特征扫描出地址并命名为符号。
- `define(name, value)` / `{$lua}`：定义常量 / 嵌入 Lua。
- `fullAccess(address, size)`：去掉内存页保护，便于写入。

## 代码注入结构示例
```
[ENABLE]
aobscan(inj, AOBPATTERN)
alloc(code, 4096)
label(return)

code:
  // 自定义逻辑（保留原指令语义）
  original_instruction
  jmp return

inj:
  jmp code
  nop
return:

[DISABLE]
inj:
  original_bytes
dealloc(code)
```

## 质量检查清单
- 原始字节已被保留。
- 跳转距离与覆盖的指令边界合法（jmp 覆盖的指令要整体替换，不能切断一条指令）。
- 分配的内存足够。
- 禁用时精确还原原始代码。
- 脚本可反复启用/禁用而不崩溃。
