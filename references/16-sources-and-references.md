# Sources & References（来源与参考资料）

本 skill 的所有技术结论以官方文档与本地实测为准。当多个来源冲突时，按下述优先级采信，并在授权的本地单机目标上实测验证。

## 来源优先级（采信顺序）
1. **官方 CE 文档 / Wiki / Help / 源码 / 论坛** —— 语法与行为的权威。
2. **成熟的逆向工程教育资源**（如 Guided Hacking、RE Stack Exchange）。
3. **社区教程与视频** —— 用于流程理解与示例，但需核验。
4. **未经验证的代码片段** —— 仅作为假设，须经本地实测确认。

## 冲突处理
- 优先采用当前官方文档。
- 在授权的本地目标上实测验证。
- 记录所用的 CE 版本与目标版本（偏移/字节会随版本变化）。
- 不要把未验证的脚本当作稳定方案给出。
- 遇到反作弊 / 在线多人相关诉求，按 `references/15-protection-and-limitations.md` 的边界处理，不提供绕过方案。

## 官方来源（首选）
- Cheat Engine Wiki: https://wiki.cheatengine.org/
- Cheat Engine Help: https://wiki.cheatengine.org/index.php?title=Cheat_Engine:Help_File
- Cheat Engine 官网: https://www.cheatengine.org/
- CE 源码仓库: https://github.com/cheat-engine/cheat-engine
- CE 论坛: https://forum.cheatengine.org/
- CE Lua 文档: https://wiki.cheatengine.org/index.php?title=Lua
- CE Auto Assembler 文档: https://wiki.cheatengine.org/index.php?title=Cheat_Engine:Auto_Assembler

**用法：**
- 写 AA 脚本前，先核对 Auto Assembler 语法与当前 CE 版本差异。
- 用 Lua 前，以 Lua 文档为准（注意 CE 绑定的是特定 Lua 版本）。
- 论坛用于检索真实案例，但需自行判断安全性与适用性。

## 学习资源
**系统化教程（推荐起步）：**
- Guided Hacking: https://guidedhacking.com/ （从基础到代码注入的系统教程）
- Reverse Engineering Stack Exchange: https://reverseengineering.stackexchange.com/ （概念与排错问答）

**Lua 与脚本：**
- Lua 官方手册: https://www.lua.org/manual/ （注意 CE 绑定的 Lua 版本可能略旧）
- CE Lua 文档: https://wiki.cheatengine.org/index.php?title=Lua

**社区资料（仅作示例/截图参考）：**
中文博客、CSDN、云平台文章与视频对"界面长什么样、步骤顺序"有帮助，但：
- 技术声明需对应当前官方文档核对；
- 偏移、字节、指令会随游戏版本变化，不能直接照搬；
- 优先用其"思路"，而非其"数值"。

## 实操清单
- [ ] 语法/字节是否对照官方文档？
- [ ] 是否在本地目标实测通过？
- [ ] 是否标注了游戏/CE 版本？
- [ ] 是否避免了未验证即宣称"稳定"？
