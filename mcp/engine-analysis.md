---
mcp_bridge_repo: https://github.com/miscusi-peek/cheatengine-mcp-bridge
mcp_server_name: cheatengine
verified_bridge_version: v12.0.0
verified_ref: unknown
verified_date: 2026-08-03
verified_env: Windows 11 x64 / Cheat Engine MCP Bridge v12.0.0
compatibility: Partial
decay_type: methodology
recheck_trigger: Bridge 升版、工具改名、参数或返回结构变更
note: >-
  Unity IL2CPP 路径经实测；Unity Mono 与 Unreal 路径未在本环境实测。
---

# 游戏引擎分析模块 (Engine Analysis)

> 针对不同游戏引擎的定位策略。对应适配要求 7。
> 所有定位均通过 `mcp/mcp-tools.md` 的真实 MCP 工具完成，不写 MCP 实现代码。

## 0. 通用对象分析流程

无论哪种引擎，稳定定位都遵循：
1. **识别对象基址**（指针链 `read_pointer_chain` / 符号 `get_symbol_address` / RTTI `get_rtti_classname`）。
2. **推测字段**（`dissect_structure` / `analyze_pointer_access`）。
3. **固化复用**（`create_structure` + `add_element_to_structure` + `register_symbol`）。
4. **CE 验证**（`read_integer(base+offset)` 复核）。

---

## 1. Unity Mono（托管）

- **特征**：C# 跑在 Mono 运行时，类名/字段名在托管堆可读，反射友好。
- **工具**：
  - `get_symbol_address("Namespace.Class:Field")` 或 Mono 符号定位（CE 的 Mono 功能可通过 `evaluate_lua` 调用 `mono_*` API）。
  - `read_pointer_chain` 跟静态/实例字段。
- **流程**：
  1. 用 CE Mono 枚举（`references/14-mono-and-managed-games.md`）找到 `ClassName:FieldName` 的地址。
  2. 实例字段需先拿到对象实例指针（通常经静态域 → 实例）。
  3. `read_integer`/`read_string` 按字段类型读取。
  4. 用 `create_structure` 固化类布局。
- **优点**：无需逆向偏移，字段名即文档。

---

## 2. Unity IL2CPP（按类型信息可用性分支）

IL2CPP 把 C# 编译为 C++，类型信息被剥离或混淆。
**入口选择取决于能否拿到可靠的类型信息，而不是取决于「这是 IL2CPP」。**
先做下面这个判定，再选路径。

### 判定：类型信息是否可靠？

判定为可靠需同时满足：

- 能 dump 出 `global-metadata.dat` / `dump.cs`，且**类名与字段名未被混淆成无意义符号**；
- 目标字段能在 dump 中定位到明确的 `Class::field` 与编译期偏移；
- dump 的版本与**当前运行的游戏版本一致**。

### 路径 A：类型信息可靠 → Class → Field → Offset → CE 验证

1. **Class**：从 IL2CPP 元数据（Il2CppDumper 输出的 `dump.cs` / 符号）取目标类及字段的编译期偏移。
2. **Field**：在 dump 中找到 `Class::fieldName` 的相对偏移（如 `0x48`）。
3. **Offset**：用 `get_symbol_address` / `get_rtti_classname` 或已知指针链定位**实例基址**；
   字段真实地址 = `instance_base + field_offset`。
4. **CE 验证**：`read_integer(instance_base + 0x48)`（或 `read_pointer_chain`）复核值符合预期，
   再用 `create_structure` / `add_element_to_structure` 固化，最后才做修改或注入。

**优势**：偏移来自元数据，比运行时扫描更 deterministic；字段密集时不会产生海量候选；
游戏更新后重新 dump 比对偏移即可，不必重扫（见 `mcp/troubleshooting.md` 版本更新失效）。

### 路径 B：类型信息缺失 / 混淆 / 无法映射 → CE 扫描是合理入口

出现下列任一情况时，**扫描不是偷懒，而是正确选择**：

- 类名字段名被混淆（`Class_0x1A2B` / 单字母符号），dump 出来也对不上业务含义；
- metadata 被加密、自定义打包，或 dump 工具与游戏版本不兼容；
- 字段被包装（属性 getter/setter、结构体嵌套、装箱），编译期偏移不指向实际存储；
- 显示值经过运行时计算（`基础值 × 系数`），字段值与 UI 不一致；
- 对象生命周期短或被 GC 移动，静态偏移无法稳定定位实例。

此时走常规路径：`scan_all` → 变化筛选 `next_scan` → `find_references` 定位访问代码 →
从指令回溯对象基址（`workflows/08-trace-back-to-base.md`）→ `dissect_structure` 还原布局。
**用运行时观察反推结构，比信任一份对不上的 dump 更可靠。**

### 混合用法（常见且推荐）

两条路径不互斥：用 dump 缩小范围（知道字段大致偏移区间），用扫描确认实际地址；
或先扫到地址，再回 dump 反查它属于哪个类的哪个字段。

> **不要把「这是 IL2CPP」当成禁止内存扫描的理由。**
> 真正要避免的是**在类型信息可靠时仍然盲扫**——那才是浪费。
> 类型信息不可用时，扫描是唯一入口。

---

## 3. Unreal Engine

- **特征**：大量 `UObject`，类名可通过 RTTI 或 GObjects/GNames 数组遍历得到。
- **工具**：
  - `get_rtti_classname(address)` 识别 C++ 对象类型。
  - `dissect_structure(address)` 看 `UObject` 布局（一般前 8/16 字节含 `ClassPrivate`/`NamePrivate` 等）。
  - `read_pointer_chain` 从 GObjects 遍历到具体 Actor/Component。
- **流程**：
  1. 用 `enum_modules` 确认 `UE4/UE5` 主模块与 `Engine` 模块。
  2. `get_rtti_classname` 抽样识别对象类型，建立类 → 偏移映射。
  3. 通过 GObjects（`evaluate_lua` 或符号定位数组基址）遍历实例。
  4. 对目标 `AActor`/`UComponent` 用 `dissect_structure` + `create_structure` 固化字段。
  5. `read_integer`/`read_float` 按偏移读写。

---

## 4. 引擎无关的进阶

- **结构体复用**：跨关卡/重载，`create_structure` 固化的布局可重复挂载到不同实例。
- **符号优先级**：能用 `get_symbol_address` 就用符号，避免硬编码地址；重启失效时符号仍稳定。
- **共享代码判定**：同一份写入代码服务玩家与敌人时，参考 `references/11-shared-code-and-object-filtering.md` 与 `workflows/11-handle-shared-code.md` 做对象过滤（如比较 `this`/寄存器里的实例指针），再注入。
- **托管 vs 原生**：Mono 走反射，IL2CPP/UE 走偏移+RTTI，先做引擎判定再选路径（见 `mcp/tool-mapping.md` 决策树）。

## 5. 与 MCP 工具的映射小结

| 引擎 | 首选定位 | 核心工具 |
|---|---|---|
| Unity Mono | 类名:字段 符号 | `get_symbol_address`, `evaluate_lua`(mono API) |
| Unity IL2CPP（类型信息可靠） | dump 偏移 + 实例基址 | `get_rtti_classname`, `read_pointer_chain`, `create_structure` |
| Unity IL2CPP（混淆 / 无 dump） | 数值扫描 + 代码访问回溯 | `scan_all`, `next_scan`, `find_references`, `dissect_structure` |
| Unreal | RTTI + GObjects 遍历 | `get_rtti_classname`, `dissect_structure`, `enum_modules` |
