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

## 2. Unity IL2CPP（⚠️ 关键规则）

> **不要优先盲目扫描数值。** IL2CPP 把 C# 编译为 C++，类型信息被剥离/混淆，盲目扫描极易误判且效率极低。

**正确顺序：Class → Field → Offset → CE 验证**

1. **Class（类定义）**：从 IL2CPP 元数据（如 Il2CppDumper 输出的 `dump.cs` / 符号）取得目标类及其字段的**编译期偏移**。
2. **Field（字段偏移）**：在 `dump.cs` 中找到 `Class::fieldName` 的相对偏移（如 `0x48`）。
3. **Offset（定位实例）**：通过 `get_symbol_address` / `get_rtti_classname` 或已知指针链定位**类实例基址**；字段真实地址 = `instance_base + field_offset`。
4. **CE 验证**：用 `read_integer(instance_base + 0x48)`（或 `read_pointer_chain`）读取，**确认值符合预期**后，再用 `create_structure`/`add_element_to_structure` 固化，最后才做修改或注入。

**为什么这样更稳**
- IL2CPP 值类型多为 float/int 且字段密集，盲扫会产生海量候选。
- 偏移来自元数据，比运行时扫描更 deterministic；CE 仅作验证与落地。
- 游戏更新后只需重新 dump 比对偏移变化，不必重扫（见故障排查「版本更新失效」）。

**反例（避免）**：直接 `scan_all("当前血量")` 反复 `next_scan`——在 IL2CPP 下耗时且易把无关临时变量当成目标。

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
| Unity IL2CPP | dump 偏移 + 实例基址 | `get_rtti_classname`, `read_pointer_chain`, `create_structure` |
| Unreal | RTTI + GObjects 遍历 | `get_rtti_classname`, `dissect_structure`, `enum_modules` |
