# Memory Structure Analysis（内存结构分析）

CE 的结构工具（Structures / Dissect data / Grouped view）可以一次性查看一个对象在多个偏移上的值，并横向比较玩家、敌人、NPC 等多个实例，从而还原对象布局。

## 准备多实例
- 同时捕获玩家、敌人、同伴等多个同类对象的内存地址（各自一条）。
- 在地址列表选中这些地址 → 右键 Grouped view，或新建 Structure 后手动 Add 多个实例地址。

## 重点查看的字段（偏移）
- 当前血量 / 最大血量（health / maxHealth）
- 对象 ID、类型字段（type / id / species）
- 队伍 / 阵营字段（team / faction）
- 坐标（x, y, z）
- 指向名称或组件的指针（name ptr、component ptr）
- 多个同类对象共享的稳定偏移（结构布局一致）

## 方法
1. 捕获玩家与非玩家对象，按可能的基址对齐。
2. 逐偏移对比：哪些偏移在所有对象里都是某固定含义（如 0x10=hp，0x14=maxhp）。
3. 优先找**区分性字段**（ID、team、type、是否玩家标志），它比「一直变的值」更有用——是后续共享代码过滤的判别依据。
4. 确认结构在多次重启/场景切换后偏移是否稳定（结构布局通常编译期固定，比数值地址稳定）。

## 衔接
- 找到判别字段后，进入 `references/11-shared-code-and-object-filtering.md` 做按对象分支。
- 结构布局是 `workflows/09-analyze-data-structure.md` 与 `workflows/10-identify-player-object.md` 的基础。
