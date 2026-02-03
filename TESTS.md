# 测试计划：电源规则脚本（Altium）

## 范围
验证 JSON 解析、规则创建/更新、过孔数量计算、铜皮连接样式、幂等性。

## 前置条件
- 在 Altium 中打开 PCB 文档。
- 确保 `C:\Projects\pcb\rules.json` 存在。
- 如需使用用例，在 `rules.json` 中设置 `test_fixture` 为 `C:\Projects\pcb\test_fixtures\` 下的文件名。
- 确保 `C:\Projects\pcb\rules_run.log` 可写（不存在会自动创建）。
- Ensure nets referenced in JSON exist in the PCB (e.g., VIN/VOUT/SW/FB/PGND/AGND).

## 测试用例

### 1) 基本用例（最小 JSON）
**输入：** 仅 `fabrication`、`power_nets[0]`、`special_nets`。  
**预期：**
- Net classes: `PWR_HIGH`, `SWITCH`, `SENSE` created.
- Rule `PWR_HIGH_Width` uses widths from JSON.
- `SWITCH_Clearance = min_clearance_mm * 2.0`.
- `PWR_HIGH_Clearance = min_clearance_mm * 1.5`.
- Rule `PWR_HIGH_Via_MinX` created.
- Popup message includes computed via count.

### 2) 多电源网（最大电流）
**输入：** `power_nets` 中 `imax_a` = 5, 10, 12。  
**预期：**
- `PWR_HIGH` includes all three nets.
- `PWR_HIGH_Via_Min12` created (ceil(12/1)=12).

### 3) 铜皮连接样式
**输入：** `grounds.connect_style = { PGND: direct, AGND: thermal }`。  
**预期：**
- `PGND_PolygonConnect` rule created with direct connect.
- `AGND_PolygonConnect` rule created with thermal relief.

### 4) 缺省字段（默认值）
**输入：** 缺少 `via_imax_a` 与线宽字段。  
**预期：**
- Defaults used (`via_imax_a = 1A`, widths = 7.2/9.0/12.0 mm).
- Script completes without error.

### 5) 幂等性
**输入：** 同一 JSON 连续运行两次。  
**预期：**
- No duplicate rules/classes.
- Existing rules updated in place.

### 6) 类型错误（鲁棒性）
**输入：** `min_clearance_mm` 为字符串。  
**预期：**
- Default clearance used.
- Script completes without crash.

## 手工验证步骤
1. 运行脚本：`DXP` → `Run Script` → `CreatePowerRulesFromJson.pas`。
2. 打开 PCB Rules 并确认：
   - Net Class 成员是否正确。
   - `PWR_HIGH_Width` 的线宽是否匹配 JSON。
   - `SWITCH_Clearance` / `PWR_HIGH_Clearance` 是否正确。
   - Via Style 规则名包含最小过孔数量。
   - 启用时是否生成铜皮连接规则。

## UI 位置映射（Altium）
在 PCB Rules & Constraints Editor 中查看：
- Net Classes：`Design` → `Classes` → `Net Classes`
- Routing Width：`Design` → `Rules` → `Routing` → `Width`
- Clearance：`Design` → `Rules` → `Electrical` → `Clearance`
- Via Style：`Design` → `Rules` → `Routing` → `Via Style`
- Routing Layers：`Design` → `Rules` → `Routing` → `Routing Layers`
- Polygon Connect Style：`Design` → `Rules` → `Plane` → `Polygon Connect Style`

## 测试用例文件
JSON fixtures 位于 `test_fixtures/`。
