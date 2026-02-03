# AI 辅助电源 PCB 规则生成（Altium）

## 背景
本项目用于将电源类 PCB 的设计需求（JSON）自动映射为 Altium 规则与 Net Class，主要覆盖电源大电流布线、间距、过孔样式、层限制、以及地网络的铜皮连接方式。适用于 4 层、10A、1oz、温升 10°C 等典型电源板场景。

## 文件组织
- `CreatePowerRulesFromJson.pas`：Altium DelphiScript 脚本，读取 JSON 并创建/更新规则。
- `REQUIREMENTS.md`：需求说明（字段、输入输出、约束）。
- `DESIGN.md`：设计说明（数据流、规则映射、限制）。
- `TESTS.md`：测试计划与人工验证步骤。
- `test_fixtures/`：测试用例 JSON（可通过 `test_fixture` 触发）。
- `rules.json`：默认输入模板。
- `rules_template.json`：空白字段模板。
- `rules_template.jsonc`：带中文注释的模板（JSONC）。
- `rules_run.log`：运行日志示例（实际运行会更新）。
- `CHANGELOG.md`：更新记录。
- `LICENSE`：MIT 许可。
- `VERSION`：版本号。

## 如何使用
1. 准备 JSON：可从 `rules.json` 复制到 `C:\Projects\pcb\rules.json`。
2. 可选：在 `rules.json` 中设置 `test_fixture` 指向 `test_fixtures` 下的文件名（如 `basic.json`）。
3. 在 Altium 打开 PCB：
   - `DXP` → `Run Script` → 选择 `CreatePowerRulesFromJson.pas`。
4. 规则写入完成后，会弹出提示并写入日志 `C:\Projects\pcb\rules_run.log`。

## 快速开始（示例 JSON）
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
    },
    {
      "name": "VOUT",
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

## 如何测试
1. 将 `C:\Projects\pcb\test_fixtures\` 下的用例复制到你的工程目录（或直接使用）。
2. 在 `rules.json` 中设置 `test_fixture`。
3. 运行脚本后，按 `TESTS.md` 中的“UI 位置映射”逐项检查规则是否生效。

## 规则映射表（速览）
| JSON 字段 | Altium 规则/对象 | 说明 |
|---|---|---|
| `power_nets[].name` | Net Class `PWR_HIGH` | 电源网加入 PWR_HIGH |
| `power_nets[].width_min_mm` | Routing Width | 最小线宽 |
| `power_nets[].width_pref_mm` | Routing Width | 推荐线宽 |
| `power_nets[].width_max_mm` | Routing Width | 最大线宽 |
| `fabrication.min_clearance_mm` | Clearance | 基础间距 |
| `special_nets[].class=SWITCH` | Clearance | SWITCH 间距 = min_clearance×2 |
| `special_nets[].class=SENSE` | Net Class `SENSE` | 反馈/敏感网络 |
| `fabrication.via_drill_mm` | Via Style | 过孔孔径 |
| `fabrication.via_dia_mm` | Via Style | 过孔外径 |
| `fabrication.via_imax_a` | Via Style | 过孔电流能力（用于计算最小过孔数） |
| `grounds.connect_style.PGND` | Polygon Connect Style | PGND 连接方式 |
| `grounds.connect_style.AGND` | Polygon Connect Style | AGND 连接方式 |

## 模板字段说明（rules_template.json）
- `fabrication.*`：工艺与制造限制（线宽、间距、过孔）。
- `power_nets[]`：电源网络清单（名称、电流、线宽）。
- `special_nets[]`：特殊网络（开关节点、反馈/敏感网）。
- `grounds.connect_style`：地网络铜皮连接方式（直连/热焊盘）。
