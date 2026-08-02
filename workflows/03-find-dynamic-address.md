# Find Dynamic Address（查找动态地址：重启后失效）

## Goal
确认目标数值的地址在重启后是否变化，并为后续寻找稳定方案（指针或代码）做准备。成功条件：明确该地址是动态分配（重启即变）还是相对稳定（模块基址 + 偏移）。

## Prerequisites
- 已用 `workflows/01` 或 `02` 找到当前生效地址。
- 能重启目标并重新进入相同场景。

## Procedure
1. 记录当前生效地址（如 `game.exe+0x1A2B3C4` 或纯堆地址 `0x2F8C0010`）。
2. 观察地址形式：
   - 形如 `module+offset` 且来自模块 → 相对稳定，可能只需指针/符号。
   - 形如随机堆地址（`0x...`）→ 动态分配，重启必变。
3. 完全关闭并重启目标，重新执行 `workflows/01`/`02` 找到同一数值的新地址。
4. 对比两次地址：不同 → 确认动态；相同且为模块基址 → 可直接引用。
5. 若动态：进入 `workflows/04-pointer-scan.md` 寻找指针，或 `workflows/06`/`07` 找代码方案。

## Decision Branches
- 地址每次都变：必须做指针或代码注入，不能硬编码。
- 地址稳定但属于模块：可直接用 `module+offset` 作为稳定地址，见 `workflows/05-create-stable-address.md`。
- 重启后目标结构变化导致扫描失效：见 `diagnostics/03-address-changes-after-restart.md`。

## Verification
- 重启前后两次得到的地址被明确归类（动态 / 稳定）。
- 记录：两次地址、是否模块基址、下一步方案选择。
