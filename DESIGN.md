# 设计说明：电源规则生成（Altium）

## 概述
脚本读取 JSON 并映射为 Altium PCB 规则与 Net Class。目标是 4 层电源板的规则生成，线宽采用 IPC-2221 预计算值（在 JSON 中提供）。

## 数据流
1. 读取 `C:\\Projects\\pcb\\rules.json`。
   - 若存在 `test_fixture`，则改为加载 `C:\\Projects\\pcb\\test_fixtures\\<test_fixture>`。
2. 解析工艺约束、电源网、特殊网。
3. 创建/更新 Net Class。
4. 创建/更新线宽、间距、过孔样式、层限制规则。
5. 计算跨层最小过孔数量并写入规则名 + 弹窗提示。
6. 追加运行摘要到 `C:\\Projects\\pcb\\rules_run.log`。

## 规则映射
- Net Class：
  - `PWR_HIGH`：`power_nets[]` 中的电源网。
  - `SWITCH`：`special_nets[]` 中 class=SWITCH 的网。
  - `SENSE`：`special_nets[]` 中 class=SENSE 的网。
- 线宽规则：
  - `PWR_HIGH_Width` 使用 `width_min_mm` / `width_pref_mm` / `width_max_mm`。
- 间距规则：
  - `SWITCH_Clearance` = `min_clearance_mm * 2.0`。
  - `PWR_HIGH_Clearance` = `min_clearance_mm * 1.5`。
- 过孔规则：
  - `PWR_HIGH_Via_MinX` 使用 `via_drill_mm` / `via_dia_mm`，X = ceil(max(imax_a)/via_imax_a)。
- 层限制：
  - `PWR_HIGH_Layers` 限制为 Top/Bottom。
- 铜皮连接：
  - 可选 `grounds.connect_style` 将 `PGND/AGND` 映射为直连/热焊盘。

## 过孔数量逻辑
- 计算 `via_count_min = ceil(max_power_current / via_imax_a)`。
- 规则名中包含最小过孔数。
- 弹窗提示最小过孔数量。

## 限制
- 过孔数量仅作提示，不作为 DRC 强制（需通过布局规范/过孔阵列落实）。
- 脚本不计算线宽，直接使用 JSON 里的预计算值。

## 可扩展方向
- 增加 `SENSE`（FB）长度约束。
- 增加跨层过孔阵列自动放置。
