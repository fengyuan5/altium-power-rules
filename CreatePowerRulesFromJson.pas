{ CreatePowerRulesFromJson.pas
  Reads rules from JSON and creates/updates PCB net classes and rules
}

uses
    SysUtils,
    StrUtils,
    Classes,
    System.JSON;

function ReadJsonFile(const FilePath: String): String;
var
    SL: TStringList;
begin
    SL := TStringList.Create;
    try
        SL.LoadFromFile(FilePath);
        Result := SL.Text;
    finally
        SL.Free;
    end;
end;

function GetJsonNumber(Obj: TJSONObject; const Key: String; DefaultVal: Double): Double;
var
    V: TJSONValue;
begin
    V := Obj.GetValue(Key);
    if (V <> nil) and (V is TJSONNumber) then
        Result := TJSONNumber(V).AsDouble
    else
        Result := DefaultVal;
end;

function GetJsonString(Obj: TJSONObject; const Key: String; const DefaultVal: String): String;
var
    V: TJSONValue;
begin
    V := Obj.GetValue(Key);
    if (V <> nil) and (V is TJSONString) then
        Result := TJSONString(V).Value
    else
        Result := DefaultVal;
end;

function IsSafeFixtureName(const Name: String): Boolean;
var
    LowerName: String;
begin
    LowerName := LowerCase(Name);
    Result := (Pos('..', Name) = 0) and
              (Pos('\\', Name) = 0) and
              (Pos('/', Name) = 0) and
              (Pos(':', Name) = 0) and
              (RightStr(LowerName, 5) = '.json');
end;

procedure AppendRunLog(const LogPath: String; const Lines: TStringList);
var
    Existing: TStringList;
begin
    Existing := TStringList.Create;
    try
        if FileExists(LogPath) then
            Existing.LoadFromFile(LogPath);
        Existing.AddStrings(Lines);
        Existing.SaveToFile(LogPath);
    finally
        Existing.Free;
    end;
end;

function GetJsonObject(Obj: TJSONObject; const Key: String): TJSONObject;
var
    V: TJSONValue;
begin
    Result := nil;
    V := Obj.GetValue(Key);
    if (V <> nil) and (V is TJSONObject) then
        Result := TJSONObject(V);
end;

function GetJsonArray(Obj: TJSONObject; const Key: String): TJSONArray;
var
    V: TJSONValue;
begin
    Result := nil;
    V := Obj.GetValue(Key);
    if (V <> nil) and (V is TJSONArray) then
        Result := TJSONArray(V);
end;

function ConnectStyleFromString(const StyleName: String): Integer;
begin
    if SameText(StyleName, 'direct') then
        Result := eDirectConnect
    else if SameText(StyleName, 'thermal') then
        Result := eReliefConnect
    else
        Result := eReliefConnect;
end;

procedure CreateOrUpdatePolygonConnectRule(PCBBoard : IPCB_Board; RuleName, Scope : String; StyleName : String);
var
    Rule : IPCB_Rule;
begin
    Rule := PCBBoard.GetRuleByName(RuleName);
    if Rule = nil then
    begin
        Rule := PCBBoard.RulesFactory.CreateRule(eRule_PolygonConnectStyle);
        Rule.Name := RuleName;
        PCBBoard.AddPCBObject(Rule);
    end;

    Rule.Scope := Scope;
    Rule.ConnectStyle := ConnectStyleFromString(StyleName);
end;

procedure CreateOrUpdateNetClass(PCBBoard : IPCB_Board; ClassName : String; NetNames : TStringList);
var
    NetClass : IPCB_NetClass;
    i        : Integer;
    Net      : IPCB_Net;
begin
    NetClass := PCBBoard.GetNetClassByName(ClassName);
    if NetClass = nil then
    begin
        NetClass := PCBBoard.CreateNetClass;
        NetClass.Name := ClassName;
        PCBBoard.AddPCBObject(NetClass);
    end;

    NetClass.MemberObjectCount := 0;

    for i := 0 to NetNames.Count - 1 do
    begin
        Net := PCBBoard.GetNetByName(NetNames[i]);
        if Net <> nil then
            NetClass.AddMember(Net);
    end;
end;

procedure CreateOrUpdateRoutingWidthRule(PCBBoard : IPCB_Board; RuleName, Scope : String;
                                         MinWidthMM, PrefWidthMM, MaxWidthMM : Double);
var
    Rule : IPCB_Rule;
begin
    Rule := PCBBoard.GetRuleByName(RuleName);
    if Rule = nil then
    begin
        Rule := PCBBoard.RulesFactory.CreateRule(eRule_RoutingWidth);
        Rule.Name := RuleName;
        PCBBoard.AddPCBObject(Rule);
    end;

    Rule.Scope := Scope;
    Rule.MinWidth := MMsToCoord(MinWidthMM);
    Rule.PreferredWidth := MMsToCoord(PrefWidthMM);
    Rule.MaxWidth := MMsToCoord(MaxWidthMM);
end;

procedure CreateOrUpdateClearanceRule(PCBBoard : IPCB_Board; RuleName, Scope : String; ClearanceMM : Double);
var
    Rule : IPCB_Rule;
begin
    Rule := PCBBoard.GetRuleByName(RuleName);
    if Rule = nil then
    begin
        Rule := PCBBoard.RulesFactory.CreateRule(eRule_Clearance);
        Rule.Name := RuleName;
        PCBBoard.AddPCBObject(Rule);
    end;

    Rule.Scope := Scope;
    Rule.Clearance := MMsToCoord(ClearanceMM);
end;

procedure CreateOrUpdateViaStyleRule(PCBBoard : IPCB_Board; RuleName, Scope : String;
                                     ViaHoleMM, ViaDiaMM : Double);
var
    Rule : IPCB_Rule;
begin
    Rule := PCBBoard.GetRuleByName(RuleName);
    if Rule = nil then
    begin
        Rule := PCBBoard.RulesFactory.CreateRule(eRule_ViaStyle);
        Rule.Name := RuleName;
        PCBBoard.AddPCBObject(Rule);
    end;

    Rule.Scope := Scope;
    Rule.ViaHoleSize := MMsToCoord(ViaHoleMM);
    Rule.ViaDiameter := MMsToCoord(ViaDiaMM);
end;

procedure CreateOrUpdateLayerRule(PCBBoard : IPCB_Board; RuleName, Scope : String);
var
    Rule : IPCB_Rule;
begin
    Rule := PCBBoard.GetRuleByName(RuleName);
    if Rule = nil then
    begin
        Rule := PCBBoard.RulesFactory.CreateRule(eRule_RoutingLayers);
        Rule.Name := RuleName;
        PCBBoard.AddPCBObject(Rule);
    end;

    Rule.Scope := Scope;
    Rule.EnabledLayers.Clear;
    Rule.EnabledLayers.Add(eTopLayer);
    Rule.EnabledLayers.Add(eBottomLayer);
end;

function CeilDiv(A, B: Double): Integer;
var
    Q: Double;
begin
    if B <= 0 then
    begin
        Result := 0;
        Exit;
    end;
    Q := A / B;
    if Frac(Q) = 0 then
        Result := Trunc(Q)
    else
        Result := Trunc(Q) + 1;
end;

procedure Run;
var
    PCBBoard       : IPCB_Board;
    JsonText       : String;
    Root           : TJSONObject;

    Fabrication    : TJSONObject;
    PowerNets      : TJSONArray;
    SpecialNets    : TJSONArray;
    Grounds        : TJSONObject;
    GroundConnect  : TJSONObject;

    i              : Integer;
    NetObj         : TJSONObject;

    NetClassPower  : TStringList;
    NetClassSwitch : TStringList;
    NetClassSense  : TStringList;

    MinTrace       : Double;
    MinClr         : Double;
    ViaHole        : Double;
    ViaDia         : Double;
    ViaImax        : Double;

    WidthMin       : Double;
    WidthPref      : Double;
    WidthMax       : Double;

    SwitchClr      : Double;
    PowerClr       : Double;

    NetName        : String;
    NetClass       : String;

    MaxImax        : Double;
    ViaCountMin    : Integer;
    ViaRuleName    : String;

    JsonPath       : String;
    LogPath        : String;
    LogLines       : TStringList;
    FixtureName    : String;
begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = nil then
    begin
        ShowMessage('当前没有打开 PCB 文档。');
        Exit;
    end;

    JsonPath := 'C:\\Projects\\pcb\\rules.json';
    { Fixture examples:
      C:\\Projects\\pcb\\test_fixtures\\basic.json
      C:\\Projects\\pcb\\test_fixtures\\multi_power_nets.json
      C:\\Projects\\pcb\\test_fixtures\\polygon_connect.json
      C:\\Projects\\pcb\\test_fixtures\\missing_optional_fields.json
      C:\\Projects\\pcb\\test_fixtures\\idempotent_run.json
      C:\\Projects\\pcb\\test_fixtures\\type_errors.json
    }
    JsonText := ReadJsonFile(JsonPath);
    Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
    if Root = nil then
    begin
        ShowMessage('JSON 解析失败。');
        Exit;
    end;

    FixtureName := GetJsonString(Root, 'test_fixture', '');
    if FixtureName <> '' then
    begin
        if not IsSafeFixtureName(FixtureName) then
        begin
            ShowMessage('test_fixture 名称无效，请使用纯文件名且后缀为 .json。');
            Exit;
        end;
        JsonPath := 'C:\\Projects\\pcb\\test_fixtures\\' + FixtureName;
        JsonText := ReadJsonFile(JsonPath);
        Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
        if Root = nil then
        begin
            ShowMessage('测试用例 JSON 解析失败。');
            Exit;
        end;
    end;

    Fabrication := GetJsonObject(Root, 'fabrication');
    PowerNets := GetJsonArray(Root, 'power_nets');
    SpecialNets := GetJsonArray(Root, 'special_nets');
    Grounds := GetJsonObject(Root, 'grounds');
    if Grounds <> nil then
        GroundConnect := GetJsonObject(Grounds, 'connect_style')
    else
        GroundConnect := nil;

    if Fabrication = nil then
    begin
        ShowMessage('缺少 fabrication 段。');
        Exit;
    end;

    MinTrace := GetJsonNumber(Fabrication, 'min_trace_mm', 0.15);
    MinClr := GetJsonNumber(Fabrication, 'min_clearance_mm', 0.15);
    ViaHole := GetJsonNumber(Fabrication, 'via_drill_mm', 0.3);
    ViaDia := GetJsonNumber(Fabrication, 'via_dia_mm', 0.6);
    ViaImax := GetJsonNumber(Fabrication, 'via_imax_a', 1.0);

    NetClassPower := TStringList.Create;
    NetClassSwitch := TStringList.Create;
    NetClassSense := TStringList.Create;

    MaxImax := 0.0;

    if PowerNets <> nil then
    begin
        for i := 0 to PowerNets.Count - 1 do
        begin
            NetObj := PowerNets.Items[i] as TJSONObject;
            NetName := GetJsonString(NetObj, 'name', '');
            NetClass := GetJsonString(NetObj, 'class', 'PWR_HIGH');
            if NetName <> '' then
            begin
                if NetClass = 'PWR_HIGH' then
                    NetClassPower.Add(NetName);
            end;

            if i = 0 then
            begin
                WidthMin := GetJsonNumber(NetObj, 'width_min_mm', 7.2);
                WidthPref := GetJsonNumber(NetObj, 'width_pref_mm', 9.0);
                WidthMax := GetJsonNumber(NetObj, 'width_max_mm', 12.0);
            end;

            if GetJsonNumber(NetObj, 'imax_a', 0.0) > MaxImax then
                MaxImax := GetJsonNumber(NetObj, 'imax_a', 0.0);
        end;
    end;

    if SpecialNets <> nil then
    begin
        for i := 0 to SpecialNets.Count - 1 do
        begin
            NetObj := SpecialNets.Items[i] as TJSONObject;
            NetName := GetJsonString(NetObj, 'name', '');
            NetClass := GetJsonString(NetObj, 'class', '');

            if (NetName <> '') and (NetClass = 'SWITCH') then
                NetClassSwitch.Add(NetName)
            else if (NetName <> '') and (NetClass = 'SENSE') then
                NetClassSense.Add(NetName);
        end;
    end;

    if NetClassPower.Count > 0 then
        CreateOrUpdateNetClass(PCBBoard, 'PWR_HIGH', NetClassPower);
    if NetClassSwitch.Count > 0 then
        CreateOrUpdateNetClass(PCBBoard, 'SWITCH', NetClassSwitch);
    if NetClassSense.Count > 0 then
        CreateOrUpdateNetClass(PCBBoard, 'SENSE', NetClassSense);

    CreateOrUpdateRoutingWidthRule(
        PCBBoard, 'PWR_HIGH_Width', 'InNetClass(''PWR_HIGH'')',
        WidthMin, WidthPref, WidthMax
    );

    SwitchClr := MinClr * 2.0;
    PowerClr := MinClr * 1.5;

    CreateOrUpdateClearanceRule(
        PCBBoard, 'SWITCH_Clearance', 'InNetClass(''SWITCH'')', SwitchClr
    );
    CreateOrUpdateClearanceRule(
        PCBBoard, 'PWR_HIGH_Clearance', 'InNetClass(''PWR_HIGH'')', PowerClr
    );

    ViaCountMin := CeilDiv(MaxImax, ViaImax);
    if ViaCountMin < 1 then
        ViaCountMin := 1;

    ViaRuleName := 'PWR_HIGH_Via_Min' + IntToStr(ViaCountMin);

    CreateOrUpdateViaStyleRule(
        PCBBoard, ViaRuleName, 'InNetClass(''PWR_HIGH'')',
        ViaHole, ViaDia
    );

    CreateOrUpdateLayerRule(
        PCBBoard, 'PWR_HIGH_Layers', 'InNetClass(''PWR_HIGH'')'
    );

    if GroundConnect <> nil then
    begin
        CreateOrUpdatePolygonConnectRule(
            PCBBoard,
            'PGND_PolygonConnect',
            'InNet(''PGND'')',
            GetJsonString(GroundConnect, 'PGND', 'direct')
        );
        CreateOrUpdatePolygonConnectRule(
            PCBBoard,
            'AGND_PolygonConnect',
            'InNet(''AGND'')',
            GetJsonString(GroundConnect, 'AGND', 'thermal')
        );
    end;

    LogPath := 'C:\\Projects\\pcb\\rules_run.log';
    LogLines := TStringList.Create;
    try
        LogLines.Add('--- Power rules run ---');
        LogLines.Add('Source JSON: ' + JsonPath);
        if FixtureName <> '' then
            LogLines.Add('Fixture: ' + FixtureName);
        LogLines.Add('PWR_HIGH widths (mm): min=' + FloatToStr(WidthMin) +
                     ', pref=' + FloatToStr(WidthPref) +
                     ', max=' + FloatToStr(WidthMax));
        LogLines.Add('Clearance (mm): PWR_HIGH=' + FloatToStr(PowerClr) +
                     ', SWITCH=' + FloatToStr(SwitchClr));
        LogLines.Add('Via: drill=' + FloatToStr(ViaHole) +
                     ', dia=' + FloatToStr(ViaDia) +
                     ', min count=' + IntToStr(ViaCountMin));
        AppendRunLog(LogPath, LogLines);
    finally
        LogLines.Free;
    end;

    ShowMessage('已从 JSON 更新规则。跨层最小过孔数量：' + IntToStr(ViaCountMin));
end;
