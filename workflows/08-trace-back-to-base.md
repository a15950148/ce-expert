# Trace Back to Base（回溯到基类/基址）

## Goal
从一个动态值出发，向上回溯到稳定的基址或对象基类，使该值可被稳定引用，并理解它属于哪个对象结构。成功条件：得到一条「基址 + 偏移链」或「模块基址 + 偏移」，在多次重启后仍成立。

## Prerequisites
- 已用 `workflows/01`/`02` 找到目标值地址，并确认其动态（见 `workflows/03`）。
- 已读 `references/05-pointer-analysis.md` 与 `references/06-memory-structure.md`。

## Procedure
1. 在目标地址上右键 → Find out what writes/accesses this address，定位改写/读取该值的指令。
2. 在反汇编窗口双击该指令，**向上回溯**：查看它从哪里取数（源寄存器来自哪个 `lea`/`mov`）。
3. 用寄存器追踪：在写入断点触发时记录源寄存器（如 `[rax+0x10]` 中的 rax），它是对象基址候选。
4. 对 rax 指向的地址再次「Find out what writes to」或手动加入地址列表，验证它是否也是一个可分析的对象字段。
5. 重复向上回溯，直到到达一个模块基址（`module+offset`）或稳定指针链顶端。
6. 用回溯得到的偏移链构造指针，或在回溯出的代码处做注入（见 `workflows/11-handle-shared-code.md`）。

## Decision Branches
- 回溯到的是堆地址且不稳定：改用指针扫描（`workflows/04`）或代码方案。
- 回溯到模块基址：可直接用 `module+offset` 作为稳定符号。
- 多个对象共用同一段回溯代码：进入 `workflows/11` 做对象过滤。
- 回溯中断（内联/优化导致寄存器被覆盖）：换相邻的写入/访问点重新回溯。

## Verification
- 回溯到的基址/偏移链在至少两次重启后仍能解析到正确对象。
- 记录：基址来源、各级偏移、回溯路径上的关键指令。
