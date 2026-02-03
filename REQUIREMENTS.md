# AI 辅助电源 PCB 规则生成需求

## 目标
从结构化需求 JSON 生成 Altium PCB 布线约束（电源场景：4 层、10A、1oz、温升 10°C），聚焦 Net Class、线宽、间距、过孔样式与层限制。

## 输入
- JSON 文件路径：`C:\\Projects\\pcb\\rules.json`。
- 必需字段：
  - `fabrication.min_trace_mm`
  - `fabrication.min_clearance_mm`
  - `fabrication.via_drill_mm`
  - `fabrication.via_dia_mm`
  - `fabrication.via_imax_a`（默认 1A）
  - `power_nets[]`：
    - `name`
    - `class`（如 `PWR_HIGH`）
    - `imax_a`
    - `width_min_mm`
    - `width_pref_mm`
    - `width_max_mm`
  - `special_nets[]`：
    - `name`
    - `class`（`SWITCH` 或 `SENSE`）
  - `grounds.connect_style`（可选）：
    - `PGND`：`direct` 或 `thermal`
    - `AGND`：`direct` 或 `thermal`
  - `test_fixture`（可选）：
    - 若存在，将加载 `C:\Projects\pcb\test_fixtures\<test_fixture>`

## 输出
- Altium Net Class：
  - `PWR_HIGH`、`SWITCH`、`SENSE`
- Altium 规则：
  - `PWR_HIGH` 的 `Routing Width`
  - `PWR_HIGH` 与 `SWITCH` 的 `Clearance`
  - `PWR_HIGH` 的 `Via Style`
  - `PWR_HIGH` 的 `Routing Layers`（仅 Top/Bottom）
  - 提供 `PGND/AGND` 时生成 `Polygon Connect Style`
- 过孔数量提示（规则名包含 `imax_a / via_imax_a` 计算结果）。
- 运行日志：`C:\Projects\pcb\rules_run.log`。

## 约束/假设
- IPC-2221 的线宽已在 JSON 中预先计算。
- 10A 电源网只在外层布线。
- 过孔数量仅作提示（规则名 + 弹窗），不作为 DRC 强制。

## 示例 JSON（最小）
```json
{
  "fabrication": {
    "min_trace_mm": 0.15,
    "min_clearance_mm": 0.15,
    "via_drill_mm": 0.30,
    "via_dia_mm": 0.60,
    "via_imax_a": 1
  },
  "power_nets": [
    {
      "name": "VIN",
      "class": "PWR_HIGH",
      "imax_a": 10,
      "width_min_mm": 7.2,
      "width_pref_mm": 9.0,
      "width_max_mm": 12.0
    }
  ],
  "special_nets": [
    { "name": "SW", "class": "SWITCH" },
    { "name": "FB", "class": "SENSE" }
  ],
  "grounds": {
    "connect_style": {
      "PGND": "direct",
      "AGND": "thermal"
    }
  }
}
```
