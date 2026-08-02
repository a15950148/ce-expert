# ce-expert

Cheat Engine 分析专家技能包（Agent Skill），面向**本地、单机、教育及个人用途**的内存分析与调试。

覆盖：数值查找（金币 / 血量 / 弹药 / 经验 / 未知值）、动态地址、多级指针、调试器断点、
Auto Assembler、AOB 代码注入、Cheat Table 设计。已适配 **Cheat Engine MCP Bridge**。

> 仅用于自己拥有的单机程序的学习与调试。不用于在线游戏、不用于破坏他人体验或规避付费。

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

## 结构

```
SKILL.md          入口与操作原则（技能触发时全量读入）
workflows/        标准流程：扫描 → 定位写入 → 注入 → 验证
examples/         分场景实例：血量 / 金币 / 弹药 / AOB 注入 …
mcp/              MCP Bridge 工具映射、结果解析、故障排查
diagnostics/      失败时的排查路径
templates/        AA 脚本与 CT 模板
references/       速查表
```

## 维护约定

这个仓库的价值在于**踩坑后的修正**，而不是条目数量。因此有几条自律规则：

1. **判断类原则必须附带可观察的判据和硬停止点。**
   写"应视为共享指令"没用 —— 要写成"看操作数：立即数=专用可改，寄存器=通用函数禁改"。
   前者曾在实战中被连续违反两次而无人察觉。
2. **被证伪的结论保留原处并标注为反面教材**，不静默删除 —— 否则下次会沿同一条推理路径重走。
3. **经验归位到对应主题并前置**，禁止一律追加到文件末尾。
4. **环境相关的经验必须标注验证环境、验证日期与衰减类型**，
   依赖具体工具版本的条目在升版后需逐条复检（它们会静默失效）。
5. 新经验优先**合并进已有文件**，不另起平行技能。

## 已知前提

- `mcp/` 目录下的工具调用假定已接入 Cheat Engine MCP Bridge；
  没有 Bridge 时方法论仍然适用，对应操作改为 CE GUI 手动执行。
- `mcp/troubleshooting.md` 第 7 节中部分条目是 Bridge 特定版本的实现缺陷，
  文件内已标注验证日期与衰减类型，作者修复后这些条目即失效。

## 变更追溯

```bash
git log -p SKILL.md                        # 某条原则历次如何演变
git log --oneline -- examples/03-ammo.md   # 某个案例被修正过几次
```

首次提交是**已含修正的状态**，市场原版内容未留存，无法拆出 before/after。
此后的改动均有完整 diff。
