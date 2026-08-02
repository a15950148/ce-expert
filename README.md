# ce-expert

Cheat Engine 分析专家技能包（Agent Skill），面向**本地、单机、教育及个人用途**的内存分析与调试。

覆盖：数值查找（金币 / 血量 / 弹药 / 经验 / 未知值）、动态地址、多级指针、调试器断点、
Auto Assembler、AOB 代码注入、Cheat Table 设计。已适配 **Cheat Engine MCP Bridge**。

> 仅用于自己拥有的单机程序的学习与调试。不用于在线游戏、不用于破坏他人体验或规避付费。

---

## 前置条件

**「Skill 被识别」和「MCP 能工作」是两件独立的事。** 装完 skill 不代表 AI 能操作 CE。
完整可用需要下面 5 步都成立：

| # | 步骤 | 如何确认 |
|---|---|---|
| 1 | 安装 Cheat Engine | CE 能正常启动并附加进程 |
| 2 | 安装并**启动** Cheat Engine MCP Bridge | Bridge 进程在运行（它是独立于 CE 的服务） |
| 3 | Agent 客户端已配置 MCP Server，**server name = `cheatengine`** | 客户端连接器列表里显示已连接 |
| 4 | **重启 Agent 会话** | 新会话才会加载新的 MCP 配置与 skill |
| 5 | 先做一次连通性测试 | 调用 `ping` 或 `get_process_list` / `get_process_info`，确认返回 `success: true` |

第 5 步不要跳过。Bridge 未启动时，前 4 步全部"看起来正常"，
但第一个真实工具调用才会失败。

**只装了 skill、没有 Bridge 也能用**：方法论、workflow、案例全部有效，
对应操作改为在 CE GUI 里手动执行。此时 AI 应遵循 `SKILL.md` 的
**Tool Availability Fallback** 规则——给 GUI 步骤，而不是输出虚构的工具调用。

---

## 安装

把整个目录放到客户端的技能目录下，重启会话即可被识别：

| 客户端 | 路径 |
|---|---|
| WorkBuddy | `~/.workbuddy/skills/ce-expert/` |
| Claude Code | `~/.claude/skills/ce-expert/` |

```bash
git clone https://github.com/a15950148/ce-expert.git ~/.workbuddy/skills/ce-expert
```

其它客户端若不支持 Skill 机制，这些文件仍可作为普通 Markdown 参考资料使用，
方法论有效，只是不会被自动触发。

**MCP 权限说明**：`SKILL.md` 的 `allowed-tools` 只声明本 skill 自身的文件操作权限。
MCP 工具权限由宿主 Agent 的 MCP 配置管理，本 skill 不在 `allowed-tools` 里伪造或硬编码
MCP 工具权限。不同客户端对该字段的强制程度不同，接入前请查阅目标客户端的 Skill 规范。

---

## 结构

```
SKILL.md          入口：触发条件 / 核心原则 / MCP 调用规则 / 任务路由（技能触发时全量读入）
workflows/        标准流程：扫描 → 定位写入 → 注入 → 验证
examples/         分场景实例：血量 / 金币 / 弹药 / AOB 注入 …
mcp/              MCP Bridge 工具映射、结果解析、故障排查（每个文件带兼容性元数据）
diagnostics/      失败时的排查路径，入口是 00-quick-lookup.md
templates/        AA 脚本与 CT 模板
references/       速查表与规范
```

入口文件只放**执行规则与路由**，其余内容按需加载，避免 SKILL.md 膨胀成总手册。

---

## 选路决策树

```
你的状态？
├─ 还没开始 / 想学基础 ──────────────► references/01-ce-basics.md
├─ 知道要改什么，但没找到 / 没改成功
│     ├─ 已知数值搜不到 ─────────────► workflows/01 / 02（入门）
│     └─ 重启后地址失效 ─────────────► workflows/03→04→05（入门→进阶）
├─ 想做"稳定 / 永久"修改
│     ├─ 需要指针 ──────────────────► workflows/04 / 05（进阶）
│     ├─ 改写 / 读取代码 ───────────► workflows/06 / 07（进阶）
│     ├─ 多对象 / 玩家专属混淆 ─────► workflows/10 / 11（高阶）
│     └─ 注入 / AOB / 热键 ─────────► workflows/12 / 13（高阶）
├─ 想做训练器 / 表
│     ├─ Cheat Table ───────────────► workflows/14（进阶）
│     └─ Lua UI 训练器 ─────────────► workflows/15（高阶）
└─ 出现报错 / 异常 ────────────────► diagnostics/00-quick-lookup.md
```

**新手第一次用 CE** 的推荐顺序：
`references/01-ce-basics.md` → `workflows/01-modify-known-value.md`
→ `examples/01-money.md` → `references/03-value-types.md`

---

## 案例索引（examples/）

| 实例 | 对应场景 / workflow |
|---|---|
| `01-money.md` | 已知数值修改（workflow 01） |
| `02-health.md` | 未知数值（workflow 02） |
| `03-ammo.md` | 禁用写入 / 无限弹药（workflow 07） |
| `04-experience.md` | 未知数值 / 经验（workflow 02） |
| `05-multi-level-pointer.md` | 多级指针（workflow 04 / 05） |
| `06-player-only-health.md` | 玩家专属（workflow 10） |
| `07-damage-multiplier.md` | AOB 伤害倍率（workflow 12） |
| `08-aob-injection.md` | AOB 注入（workflow 12） |
| `09-shared-code-filter.md` | 共享代码过滤（workflow 11） |
| `10-lua-trainer.md` | Lua 训练器（workflow 15） |

## 模板索引（templates/）

| 模板 | 用途 |
|---|---|
| `aa-aob-injection.txt` | AOB 代码注入骨架 |
| `aa-basic-injection.txt` | 基础注入（改写 / 跳过） |
| `aa-enable-disable.txt` | enable / disable 框架 |
| `aa-register-filter.txt` | 寄存器 / 对象过滤 |
| `cheat-table-layout.md` | CT 表布局规范 |
| `lua-form.lua` | Lua 表单 UI |
| `lua-hotkey.lua` | Lua 热键 |
| `lua-toggle.lua` | Lua 开关 |

---

## 维护约定

这个仓库的价值在于**踩坑后的修正**，而不是条目数量。因此有几条自律规则：

1. **判断类原则必须附带可观察的判据和硬停止点。**
   写"应视为共享指令"没用——但**判据必须是可观察的运行时证据，不能是代码形态的推断**。
   这条自身被修正过一次：早期版本用"立即数 vs 寄存器"当判据，
   而立即数同样可能出现在多对象循环里，形态只是风险信号。
   操作数形态只能作为**风险线索**：立即数表示修改量固定；寄存器表示修改量由运行时提供。
   是否属于共享代码必须通过——命中记录、寄存器上下文、对象基址、玩家/敌人对照测试——
   进行验证。**禁止仅根据操作数形态判断代码是否专用。**
2. **被证伪的结论保留原处并标注为反面教材**，不静默删除——否则下次会沿同一条推理路径重走。
3. **经验归位到对应主题并前置**，禁止一律追加到文件末尾。
4. **环境相关的经验必须标注验证环境、验证日期与衰减类型。**
   `mcp/` 下每个文件头部都有兼容性 frontmatter，Bridge 升版后按 `decay_type` 逐条复检。
5. **新经验优先合并进已有文件**，不另起平行技能。
6. **入口文件只放执行规则与路由**，手册性内容一律下沉到子目录。

---

## 已知前提与衰减风险

- `mcp/` 下的工具调用假定已接入 Cheat Engine MCP Bridge（验证版本 **v12.0.0**，
  验证日期 **2026-08-03**）。没有 Bridge 时方法论仍适用，操作改为 CE GUI 手动执行。
- `mcp/mcp-tools.md` 的工具名与参数是从 Bridge 源码逐字提取的，
  但**仅部分工具经实测调用验证**，该文件的 MCP Compatibility 节列出了实测清单。
- `mcp/troubleshooting.md` 第 7 节中部分条目是 Bridge 特定版本的**实现缺陷**，
  作者修复后这些条目即变成误导，且**不会报错**——升版后必须整节复检。
- `verified_ref` 目前是 `unknown`。想精确锁定的话，在 Bridge 仓库执行
  `git rev-parse --short HEAD` 并回填到 `mcp/*.md` 的 frontmatter（`verified_ref`）。

---

## 变更追溯

```bash
git log -p SKILL.md                        # 某条原则历次如何演变
git log --oneline -- examples/03-ammo.md   # 某个案例被修正过几次
```

首次提交是**已含修正的状态**，市场原版内容未留存，无法拆出 before/after。
此后的改动均有完整 diff。
