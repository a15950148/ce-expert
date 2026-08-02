# Mono and Managed Games（Mono / 托管游戏）

## When this applies（适用场景）
使用 Unity（.NET/Mono）、Godot（C#）或其他 Mono/CLR 运行时的游戏，往往能通过 CE 的 **Mono 工具**暴露出高级信息：类名、字段名、方法名、以及运行时的对象实例地址。

## What CE Mono tools give you（CE 的 Mono 工具能提供）
- **类与字段清单**：直接看到 `Player.health`、`Weapon.ammo` 这类可读名称与偏移。
- **实例地址**：字段对应的运行时对象地址，省去大量手动扫描。
- **方法定位**：定位函数入口，用于调用或挂钩。

## Workflow（典型流程）
1. 打开 CE → `Mono` / `NET` 菜单 → 加载目标进程的元数据。
2. 浏览类结构，找到目标字段（如 `Player->hp`）。
3. 让字段加入地址列表，或复制其运行时地址。
4. 在对象实例上做指针/结构分析，确认稳定性。
5. 必要时用 Lua/C# 注入或调用方法（见 `references/12-lua-api.md`）。

## Caveats（注意事项）
- 托管元数据是**发现捷径**，不是终点：仍需在运行时验证地址与对象生命周期。
- 字段偏移可能随构建（build）改变——游戏更新后需重新加载元数据核对。
- 某些游戏会对元数据混淆、加密或剥离，导致 Mono 工具无法读取；此时退回常规内存扫描。
- 对象可能被频繁重建，单纯缓存地址会失效；优先用对象指针或结构路径。
- 仍然遵守安全边界：仅限授权本地单机分析（`references/15-protection-and-limitations.md`）。
