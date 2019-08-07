unit frameSutraGeneralizedFlowBoundaryUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, frameCustomSutraFeatureUnit,
  Vcl.StdCtrls, ArgusDataEntry, Vcl.Grids, RbwDataGrid4, Vcl.Buttons, Vcl.Mask,
  JvExMask, JvSpin, Vcl.ExtCtrls, JvExStdCtrls, JvCombobox, JvListComb,
  UndoItemsScreenObjects, SutraGeneralBoundaryUnit;

type
  TGenFlowCol = (gfcTime, gfcUsed, gfcPress1, gfcFlow1, gfcPress2, gfcFlow2,
    gfcLimit1, gfcLimit2, gfcInflowU, gfcOutflowType, gfcOutflowU);

  TframeSutraGeneralizedFlowBoundary = class(TframeCustomSutraTimeVaryingFeature)
    pnlEditGrid: TPanel;
    lblFormula: TLabel;
    rdeFormula: TRbwDataEntry;
    cbUsed: TCheckBox;
    comboLimit: TJvImageComboBox;
    comboExit: TJvImageComboBox;
    procedure rdgSutraFeatureSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure rdgSutraFeatureBeforeDrawCell(Sender: TObject; ACol,
      ARow: Integer);
    procedure seNumberOfTimesChange(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnInsertClick(Sender: TObject);
    procedure rdgSutraFeatureColSize(Sender: TObject; ACol,
      PriorWidth: Integer);
    procedure rdgSutraFeatureHorizontalScroll(Sender: TObject);
    procedure cbUsedClick(Sender: TObject);
    procedure comboLimitChange(Sender: TObject);
    procedure comboExitChange(Sender: TObject);
    procedure rdgSutraFeatureMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure rdeFormulaChange(Sender: TObject);
    procedure rdgSutraFeatureSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
  private
    FBoundariesTheSame: Boolean;
    procedure InitializeColumns;
    procedure GetScheduleName(BoundaryList: TSutraGeneralFlowBoundaryList);
    procedure GetBoundaryValues(BoundaryList: TSutraGeneralFlowBoundaryList);
    procedure SetBoundaryValues(BoundValues: TSutraGeneralFlowCollection);
    procedure DisplayBoundaries(BoundColl: TSutraGeneralFlowCollection);
    procedure LayoutMultiEditControls;
    { Private declarations }
  protected
    function UsedColumn: Integer; override;
  public
    procedure GetData(ScreenObjects: TScreenObjectEditCollection); override;
    procedure SetData(ScreenObjects: TScreenObjectEditCollection; SetAll,
      ClearAll: boolean); override;
    { Public declarations }
  end;

var
  frameSutraGeneralizedFlowBoundary: TframeSutraGeneralizedFlowBoundary;

implementation

uses
  SutraBoundaryUnit, SutraBoundariesUnit, SutraTimeScheduleUnit,
  AdjustSutraBoundaryValuesUnit, ScreenObjectUnit, System.Generics.Collections,
  frmGoPhastUnit, frmErrorsAndWarningsUnit, GoPhastTypes, frmCustomGoPhastUnit;

resourcestring
  StrSUTRAGeneralFlowB = 'SUTRA General Flow Boundary';

{$R *.dfm}

{ TframeSutraGeneralizedFlowBoundary }

procedure TframeSutraGeneralizedFlowBoundary.btnDeleteClick(Sender: TObject);
begin
  inherited;
//
end;

procedure TframeSutraGeneralizedFlowBoundary.btnInsertClick(Sender: TObject);
begin
  inherited;
//
end;

procedure TframeSutraGeneralizedFlowBoundary.cbUsedClick(Sender: TObject);
begin
  inherited;
  ChangeSelectedCellsStateInColumn(rdgSutraFeature, Ord(gfcUsed), cbUsed.State);
end;

procedure TframeSutraGeneralizedFlowBoundary.comboExitChange(Sender: TObject);
begin
  inherited;
  ChangeSelectedCellsInColumn(rdgSutraFeature, Ord(gfcOutflowType), comboExit.Text);
end;

procedure TframeSutraGeneralizedFlowBoundary.comboLimitChange(Sender: TObject);
var
  Col: TGenFlowCol;
begin
  inherited;
  for Col in [gfcLimit1, gfcLimit2] do
  begin
    ChangeSelectedCellsInColumn(rdgSutraFeature, Ord(Col), comboLimit.Text);
  end;
//  TGenFlowCol = (gfcTime, gfcUsed, gfcPress1, gfcFlow1, gfcPress2, gfcFlow2,
//    gfcLimit1, gfcLimit2, gfcInflowU, gfcOutflowType, gfcOutflowU);
end;

procedure TframeSutraGeneralizedFlowBoundary.DisplayBoundaries(
  BoundColl: TSutraGeneralFlowCollection);
var
  ItemIndex: Integer;
  Item: TSutraGeneralFlowItem;
begin
//  FDisplayingData := True;
  rdgSutraFeature.BeginUpdate;
  try
    seNumberOfTimes.AsInteger := BoundColl.Count;
    rdgSutraFeature.RowCount := BoundColl.Count+1;
    for ItemIndex := 0 to BoundColl.Count - 1 do
    begin
      Item := BoundColl[ItemIndex] as TSutraGeneralFlowItem;
      rdgSutraFeature.Cells[Ord(gfcTime),ItemIndex+1] := FloatToStr(Item.StartTime);
    {$IFNDEF SutraUsedFormulas}
      rdgSutraFeature.Checked[Ord(gfcUsed),ItemIndex+1] := Item.Used;
      if Item.Used then
      begin
        rdgSutraFeature.Cells[Ord(gfcPress1),ItemIndex+1] := Item.LowerPressureFormula;
        rdgSutraFeature.Cells[Ord(gfcFlow1),ItemIndex+1] := Item.LowerFlowRateFormula;
        rdgSutraFeature.Cells[Ord(gfcPress2),ItemIndex+1] := Item.HigherPressureFormula;
        rdgSutraFeature.Cells[Ord(gfcFlow2),ItemIndex+1] := Item.HigherFlowRateFormula;
        rdgSutraFeature.ItemIndex[Ord(gfcLimit1),ItemIndex+1] := Ord(Item.LowerLimitType);
        rdgSutraFeature.ItemIndex[Ord(gfcLimit2),ItemIndex+1] := Ord(Item.UpperLimitType);
        rdgSutraFeature.Cells[Ord(gfcInflowU),ItemIndex+1] := Item.UInFormula;
        rdgSutraFeature.ItemIndex[Ord(gfcOutflowType),ItemIndex+1] := Ord(Item.ExitSpecMethod);
        rdgSutraFeature.Cells[Ord(gfcOutflowU),ItemIndex+1] := Item.UoutFormula;
      end
      else
      begin
        rdgSutraFeature.Cells[Ord(gfcPress1),ItemIndex+1] := '';
        rdgSutraFeature.Cells[Ord(gfcFlow1),ItemIndex+1] := '';
        rdgSutraFeature.Cells[Ord(gfcPress2),ItemIndex+1] := '';
        rdgSutraFeature.Cells[Ord(gfcFlow2),ItemIndex+1] := '';
        rdgSutraFeature.ItemIndex[Ord(gfcLimit1),ItemIndex+1] := 0;
        rdgSutraFeature.ItemIndex[Ord(gfcLimit2),ItemIndex+1] := 0;
        rdgSutraFeature.Cells[Ord(gfcInflowU),ItemIndex+1] := '';
        rdgSutraFeature.ItemIndex[Ord(gfcOutflowType),ItemIndex+1] := 0;
        rdgSutraFeature.Cells[Ord(gfcOutflowU),ItemIndex+1] := '';
      end;
    {$ELSE}
        rdgSutraFeature.Cells[Ord(gfcUsed),ItemIndex+1] := Item.UsedFormula;
        rdgSutraFeature.Cells[Ord(gfcPress1),ItemIndex+1] := Item.LowerPressureFormula;
        rdgSutraFeature.Cells[Ord(gfcFlow1),ItemIndex+1] := Item.LowerFlowRateFormula;
        rdgSutraFeature.Cells[Ord(gfcPress2),ItemIndex+1] := Item.HigherPressureFormula;
        rdgSutraFeature.Cells[Ord(gfcFlow2),ItemIndex+1] := Item.HigherFlowRateFormula;
        rdgSutraFeature.ItemIndex[Ord(gfcLimit1),ItemIndex+1] := Ord(Item.LowerLimitType);
        rdgSutraFeature.ItemIndex[Ord(gfcLimit2),ItemIndex+1] := Ord(Item.UpperLimitType);
        rdgSutraFeature.Cells[Ord(gfcInflowU),ItemIndex+1] := Item.UInFormula;
        rdgSutraFeature.ItemIndex[Ord(gfcOutflowType),ItemIndex+1] := Ord(Item.ExitSpecMethod);
        rdgSutraFeature.Cells[Ord(gfcOutflowU),ItemIndex+1] := Item.UoutFormula;

    {$ENDIF}
    end;
  finally
    rdgSutraFeature.EndUpdate;
//    FDisplayingData := False;
  end;
end;

procedure TframeSutraGeneralizedFlowBoundary.GetBoundaryValues(
  BoundaryList: TSutraGeneralFlowBoundaryList);
var
  FirstBoundary: TSutraGeneralFlowBoundary;
  Same: Boolean;
  BoundColl: TSutraGeneralFlowCollection;
  Index: Integer;
  ABoundary: TSutraGeneralFlowBoundary;
  ASchedule: TSutraTimeSchedule;
begin
  FirstBoundary := BoundaryList[0];
  BoundColl := FirstBoundary.Values as TSutraGeneralFlowCollection;
  Same := True;
  for Index := 1 to BoundaryList.Count - 1 do
  begin
    ABoundary := BoundaryList[Index];
    Same := BoundColl.isSame(ABoundary.Values);
    if not Same then
    begin
      Break;
    end;
  end;
  FBoundariesTheSame := Same;
  if Same then
  begin
    if comboSchedule.ItemIndex >= 1 then
    begin
      ASchedule := comboSchedule.Items.Objects[comboSchedule.ItemIndex]
        as TSutraTimeSchedule;

      AdjustBoundaryValues(ASchedule, BoundColl);
    end;
//    CheckSchedule(BoundaryList);
    DisplayBoundaries(BoundColl);
  end
  else
  begin
    ClearBoundaries;
  end;
end;

procedure TframeSutraGeneralizedFlowBoundary.GetData(
  ScreenObjects: TScreenObjectEditCollection);
var
  BoundaryList: TSutraGeneralFlowBoundaryList;
  index: Integer;
  SutraBoundaries: TSutraBoundaries;
  ABoundary: TSutraGeneralFlowBoundary;
begin
  {$IFDEF SutraUsedFormulas}
  rdgSutraFeature.Columns[Ord(gfcUsed)].Format := rcf4String;
  rdgSutraFeature.Columns[Ord(gfcUsed)].ButtonUsed := True;
  rdgSutraFeature.Columns[Ord(gfcUsed)].ButtonCaption := 'F()';
  rdgSutraFeature.Columns[Ord(gfcUsed)].ButtonWidth := 35;
  cbUsed.visible := False;
  {$ENDIF}

  rdgSutraFeature.BeginUpdate;
  try
    inherited;
    ClearData;
    InitializeColumns;

    BoundaryList := TSutraGeneralFlowBoundaryList.Create;
    try
      for index := 0 to ScreenObjects.Count - 1 do
      begin
        SutraBoundaries := ScreenObjects[index].ScreenObject.SutraBoundaries;
        ABoundary := SutraBoundaries.GeneralFlowBoundary;
        if (ABoundary <> nil) and ABoundary.Used then
        begin
          BoundaryList.Add(ABoundary);
        end;
      end;

      if BoundaryList.Count = 0 then
      begin
        FCheckState := cbUnchecked;
      end
      else if ScreenObjects.Count = BoundaryList.Count then
      begin
        FCheckState := cbChecked;
      end
      else
      begin
        FCheckState := cbGrayed;
      end;
      if Assigned(OnActivate) then
      begin
        OnActivate(self, FCheckState);
      end;

      if BoundaryList.Count = 0 then
      begin
        Exit;
      end;

      GetScheduleName(BoundaryList);
      GetBoundaryValues(BoundaryList);

    finally
      BoundaryList.Free;
    end;
  finally
    rdgSutraFeature.EndUpdate;
  end;
  LayoutMultiEditControls;
end;

procedure TframeSutraGeneralizedFlowBoundary.GetScheduleName(
  BoundaryList: TSutraGeneralFlowBoundaryList);
var
  ScheduleName: AnsiString;
  Same: Boolean;
  FirstBoundary: TSutraGeneralFlowBoundary;
  ABoundColl: TSutraGeneralFlowCollection;
  BoundColl: TSutraGeneralFlowCollection;
  Index: Integer;
  ABoundary: TSutraGeneralFlowBoundary;
begin
  FirstBoundary := BoundaryList[0];
  BoundColl := FirstBoundary.Values as TSutraGeneralFlowCollection;
  ScheduleName := BoundColl.ScheduleName;
  Same := True;
  for Index := 1 to BoundaryList.Count - 1 do
  begin
    ABoundary := BoundaryList[Index];
    ABoundColl := ABoundary.Values as TSutraGeneralFlowCollection;
    Same := ScheduleName = ABoundColl.ScheduleName;
    if not Same then
    begin
      Break;
    end;
  end;
  SetScheduleIndex(ScheduleName, Same);
end;

procedure TframeSutraGeneralizedFlowBoundary.InitializeColumns;
var
  ColIndex: Integer;
  AColumn: TRbwColumn4;
  Limits: TStringList;
  ExitSpec: TStringList;
  ColFormat: TGenFlowCol;
  ItemIndex: Integer;
begin
  Limits := TStringList.Create;
  ExitSpec := TStringList.Create;
  try
    for ItemIndex := 0 to comboLimit.Items.Count - 1 do
    begin
      Limits.Add(comboLimit.Items[ItemIndex].Text)
    end;
    for ItemIndex := 0 to comboExit.Items.Count - 1 do
    begin
      ExitSpec.Add(comboExit.Items[ItemIndex].Text)
    end;
    for ColIndex := 0 to rdgSutraFeature.ColCount - 1 do
    begin
      ColFormat := TGenFlowCol(ColIndex);
      AColumn := rdgSutraFeature.Columns[ColIndex];
      AColumn.AutoAdjustColWidths := True;
      AColumn.AutoAdjustRowHeights := True;
      AColumn.WordWrapCaptions := True;
      if ColFormat in [gfcLimit1, gfcLimit2] then
      begin
        AColumn.ComboUsed := True;
        AColumn.PickList := Limits;
        AColumn.Format := rcf4String;
        AColumn.LimitToList := True;
      end
      else if ColFormat = gfcOutflowType then
      begin
        AColumn.ComboUsed := True;
        AColumn.PickList := ExitSpec;
        AColumn.Format := rcf4String;
        AColumn.LimitToList := True;
      end
      {$IFNDEF SutraUsedFormulas}
      else if ColFormat = gfcUsed then
      begin
        AColumn.Format := rcf4Boolean;
      end
      {$ENDIF}
      else if ColFormat = gfcTime then
      begin
        AColumn.Format := rcf4Real;
      end
      else
      begin
        AColumn.Format := rcf4String;
        AColumn.ButtonUsed := True;
        AColumn.ButtonCaption := 'F()';
        AColumn.ButtonWidth := 40;
      end;
    end;
  finally
    Limits.Free;
    ExitSpec.Free;
  end;

  rdgSutraFeature.Cells[Ord(gfcTime), 0] := 'Time';
  rdgSutraFeature.Cells[Ord(gfcUsed), 0] := 'Used (IPBG1)';
  rdgSutraFeature.Cells[Ord(gfcPress1), 0] := 'Pressure 1 (PBG11)';
  rdgSutraFeature.Cells[Ord(gfcFlow1), 0] := 'Flow 1 (QPBG11)';
  rdgSutraFeature.Cells[Ord(gfcPress2), 0] := 'Pressure 2 (PBG21)';
  rdgSutraFeature.Cells[Ord(gfcFlow2), 0] := 'Flow 2 (QPBG21)';
  rdgSutraFeature.Cells[Ord(gfcLimit1), 0] := 'Limit 1 (CPQL11)';
  rdgSutraFeature.Cells[Ord(gfcLimit2), 0] := 'Limit 2 (CPQL21)';
  rdgSutraFeature.Cells[Ord(gfcInflowU), 0] := 'Inflow U (UPBGI1)';
  rdgSutraFeature.Cells[Ord(gfcOutflowType), 0] := 'Outflow U Specification Method (CPBGO1)';
  rdgSutraFeature.Cells[Ord(gfcOutflowU), 0] := 'Outflow U (UPBGO1)';
end;

procedure TframeSutraGeneralizedFlowBoundary.LayoutMultiEditControls;
var
  FirstVisibleFormulaCol: TGenFlowCol;
  ColIndex: TGenFlowCol;
begin
  if [csLoading, csReading] * ComponentState <> [] then
  begin
    Exit
  end;

{$IFNDEF SutraUsedFormulas}
  if rdgSutraFeature.ColVisible[Ord(gfcUsed)] then
  begin
    cbUsed.Visible := True;
    LayoutControls(rdgSutraFeature, cbUsed, nil, Ord(gfcUsed));
  end
  else
  begin
    cbUsed.Visible := False;
  end;
{$ENDIF}

  {$IFDEF SutraUsedFormulas}
  FirstVisibleFormulaCol := gfcUsed;
  {$ELSE}
  FirstVisibleFormulaCol := gfcPress1;
  {$ENDIF}

  for ColIndex := FirstVisibleFormulaCol to High(TGenFlowCol) do
  begin
    if ColIndex in [gfcLimit1, gfcLimit2, gfcOutflowType] then
    begin
      Continue;
    end;
    if rdgSutraFeature.ColVisible[Ord(ColIndex)] then
    begin
      FirstVisibleFormulaCol := ColIndex;
      break;
    end;
  end;
  LayoutControls(rdgSutraFeature, rdeFormula, lblFormula, Ord(FirstVisibleFormulaCol));

  if rdgSutraFeature.ColVisible[Ord(gfcLimit1)] then
  begin
    comboLimit.Visible := True;
    LayoutControls(rdgSutraFeature, comboLimit, nil, Ord(gfcLimit1));
  end
  else if rdgSutraFeature.ColVisible[Ord(gfcLimit2)] then
  begin
    comboLimit.Visible := True;
    LayoutControls(rdgSutraFeature, comboLimit, nil, Ord(gfcLimit2));
  end
  else
  begin
    comboLimit.Visible := False;
  end;
  if rdgSutraFeature.ColVisible[Ord(gfcOutflowType)] then
  begin
    comboExit.Visible := True;
    LayoutControls(rdgSutraFeature, comboExit, nil, Ord(gfcOutflowType));
  end
  else
  begin
    comboExit.Visible := False;
  end;
end;

procedure TframeSutraGeneralizedFlowBoundary.rdeFormulaChange(Sender: TObject);
var
  Col: TGenFlowCol;
begin
  inherited;
{$IFDEF SutraUsedFormulas}
  for Col in [gfcUsed, gfcPress1, gfcFlow1, gfcPress2, gfcFlow2, gfcInflowU, gfcOutflowU] do
{$ELSE}
  for Col in [gfcPress1, gfcFlow1, gfcPress2, gfcFlow2, gfcInflowU, gfcOutflowU] do
{$ENDIF}
  begin
    ChangeSelectedCellsInColumn(rdgSutraFeature, Ord(Col), rdeFormula.Text);
  end;
end;

procedure TframeSutraGeneralizedFlowBoundary.rdgSutraFeatureBeforeDrawCell(
  Sender: TObject; ACol, ARow: Integer);
var
  CanSelect: Boolean;
begin
  inherited;
  CanSelect := True;
  rdgSutraFeatureSelectCell(Sender, ACol, ARow, CanSelect);
  if not CanSelect then
  begin
    rdgSutraFeature.Canvas.Brush.Color := clBtnFace;
  end;
end;

procedure TframeSutraGeneralizedFlowBoundary.rdgSutraFeatureColSize(
  Sender: TObject; ACol, PriorWidth: Integer);
begin
  inherited;
  LayoutMultiEditControls;
end;

procedure TframeSutraGeneralizedFlowBoundary.rdgSutraFeatureHorizontalScroll(
  Sender: TObject);
begin
  inherited;
  LayoutMultiEditControls
end;

procedure TframeSutraGeneralizedFlowBoundary.rdgSutraFeatureMouseUp(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
{$IFNDEF SutraUsedFormulas}
  EnableMultiEditControl(rdgSutraFeature, cbUsed, Ord(gfcUsed));
{$ENDIF}
  EnableMultiEditControl(rdgSutraFeature, rdeFormula, [Ord(gfcPress1),
    Ord(gfcFlow1), Ord(gfcPress2), Ord(gfcFlow2), Ord(gfcInflowU),
    Ord(gfcOutflowU)]);
  EnableMultiEditControl(rdgSutraFeature, comboLimit, [Ord(gfcLimit1),
    Ord(gfcLimit2)]);
  EnableMultiEditControl(rdgSutraFeature, comboExit, Ord(gfcOutflowType));
end;

procedure TframeSutraGeneralizedFlowBoundary.rdgSutraFeatureSelectCell(
  Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  inherited;
{$IFNDEF SutraUsedFormulas}
  if ARow > 0 then
  begin
    if ACol > Ord(gfcUsed) then
    begin
      CanSelect := rdgSutraFeature.Checked[Ord(gfcUsed), ARow];
    end;
  end;
{$ENDIF}
  if not rdgSutraFeature.Drawing then
  begin
    LayoutMultiEditControls;
  end;
end;

procedure TframeSutraGeneralizedFlowBoundary.rdgSutraFeatureSetEditText(
  Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  inherited;
  if Value <> '' then
  begin
    seNumberOfTimes.AsInteger := rdgSutraFeature.RowCount -1;
  end;
end;

procedure TframeSutraGeneralizedFlowBoundary.seNumberOfTimesChange(
  Sender: TObject);
begin
  inherited;
  UpdateCheckState;
end;

procedure TframeSutraGeneralizedFlowBoundary.SetBoundaryValues(
  BoundValues: TSutraGeneralFlowCollection);
var
  ColIndex: Integer;
//  AssocItem: TCustomSutraAssociatedBoundaryItem;
  ItemIndex: Integer;
  RowIndex: Integer;
  BoundItem: TSutraGeneralFlowItem;
  ATime: Extended;
  OK: Boolean;
  StartIndex: Integer;
//  Initialtime: Double;
//  BoundaryTypeString: string;
begin
  if seNumberOfTimes.AsInteger > 0 then
  begin
//    Initialtime := frmGoPhast.PhastModel.SutraTimeOptions.InitialTime;
    ItemIndex := 0;
    for RowIndex := 1 to seNumberOfTimes.AsInteger do
    begin
      if TryStrToFloat(rdgSutraFeature.Cells[0, RowIndex], ATime) then
      begin
        OK := False;
      {$IFNDEF SutraUsedFormulas}
        if not rdgSutraFeature.Checked[1, RowIndex] then
        begin
          OK := True;
        end
        else
        begin
      StartIndex := Ord(gfcPress1);
      {$ELSE}
      StartIndex := Ord(gfcUsed);
      {$ENDIF}
          for ColIndex := StartIndex to rdgSutraFeature.ColCount - 1 do
          begin
            OK := rdgSutraFeature.Cells[ColIndex, RowIndex] <> '';
            if not OK then
            begin
              Break;
            end;
          end;
      {$IFNDEF SutraUsedFormulas}
        end;
      {$ENDIF}
        if OK then
        begin
          if ItemIndex < BoundValues.Count then
          begin
            BoundItem := BoundValues.Items[ItemIndex] as TSutraGeneralFlowItem;
          end
          else
          begin
            BoundItem := BoundValues.Add as TSutraGeneralFlowItem;
          end;
//          if ATime <= Initialtime then
//          begin
//            BoundaryTypeString := StrSUTRAGeneralFlowB;
//            frmErrorsAndWarnings.AddError(frmGoPhast.PhastModel,
//              StrInvalidBoundaryTim,
//              Format(StrInSTheFirstSpe, [BoundaryTypeString])
//              );
//            frmErrorsAndWarnings.Show;
//          end;
          BoundItem.StartTime := ATime;
        {$IFNDEF SutraUsedFormulas}
          BoundItem.Used := rdgSutraFeature.Checked[UsedColumn, RowIndex];
          if BoundItem.Used then
          begin
            BoundItem.LowerPressureFormula := rdgSutraFeature.Cells[Ord(gfcPress1), RowIndex];
            BoundItem.LowerPressureFormula := rdgSutraFeature.Cells[Ord(gfcPress1),ItemIndex+1];
            BoundItem.LowerFlowRateFormula := rdgSutraFeature.Cells[Ord(gfcFlow1),ItemIndex+1];
            BoundItem.HigherPressureFormula := rdgSutraFeature.Cells[Ord(gfcPress2),ItemIndex+1];
            BoundItem.HigherFlowRateFormula := rdgSutraFeature.Cells[Ord(gfcFlow2),ItemIndex+1];
            BoundItem.LowerLimitType := TSutraLimitType(rdgSutraFeature.ItemIndex[Ord(gfcLimit1),ItemIndex+1]);
            BoundItem.UpperLimitType := TSutraLimitType(rdgSutraFeature.ItemIndex[Ord(gfcLimit2),ItemIndex+1]);
            BoundItem.UInFormula := rdgSutraFeature.Cells[Ord(gfcInflowU),ItemIndex+1];
            BoundItem.ExitSpecMethod := TSutraExitSpecificationMethod(rdgSutraFeature.ItemIndex[Ord(gfcOutflowType),ItemIndex+1]);
            BoundItem.UoutFormula := rdgSutraFeature.Cells[Ord(gfcOutflowU),ItemIndex+1];
          end;
        {$ELSE}
            BoundItem.UsedFormula := rdgSutraFeature.Cells[Ord(gfcUsed), RowIndex];
            BoundItem.LowerPressureFormula := rdgSutraFeature.Cells[Ord(gfcPress1), RowIndex];
            BoundItem.LowerPressureFormula := rdgSutraFeature.Cells[Ord(gfcPress1),ItemIndex+1];
            BoundItem.LowerFlowRateFormula := rdgSutraFeature.Cells[Ord(gfcFlow1),ItemIndex+1];
            BoundItem.HigherPressureFormula := rdgSutraFeature.Cells[Ord(gfcPress2),ItemIndex+1];
            BoundItem.HigherFlowRateFormula := rdgSutraFeature.Cells[Ord(gfcFlow2),ItemIndex+1];
            BoundItem.LowerLimitType := TSutraLimitType(rdgSutraFeature.ItemIndex[Ord(gfcLimit1),ItemIndex+1]);
            BoundItem.UpperLimitType := TSutraLimitType(rdgSutraFeature.ItemIndex[Ord(gfcLimit2),ItemIndex+1]);
            BoundItem.UInFormula := rdgSutraFeature.Cells[Ord(gfcInflowU),ItemIndex+1];
            BoundItem.ExitSpecMethod := TSutraExitSpecificationMethod(rdgSutraFeature.ItemIndex[Ord(gfcOutflowType),ItemIndex+1]);
            BoundItem.UoutFormula := rdgSutraFeature.Cells[Ord(gfcOutflowU),ItemIndex+1];
        {$ENDIF}
          Inc(ItemIndex);
        end;
      end;
      while BoundValues.Count > ItemIndex do
      begin
        BoundValues.Delete(BoundValues.Count - 1);
      end;
    end;
  end;
end;

procedure TframeSutraGeneralizedFlowBoundary.SetData(
  ScreenObjects: TScreenObjectEditCollection; SetAll, ClearAll: boolean);
var
  BoundaryList: TSutraGeneralFlowBoundaryList;
  index: integer;
  SutraBoundaries: TSutraBoundaries;
  ABoundary: TSutraGeneralFlowBoundary;
  LocalScreenObjects: TList<TScreenObject>;
  BoundValues: TSutraGeneralFlowCollection;
begin
  inherited;
  LocalScreenObjects := TList<TScreenObject>.Create;
  BoundaryList := TSutraGeneralFlowBoundaryList.Create;
  try
    for index := 0 to ScreenObjects.Count - 1 do
    begin
//      ABoundary := nil;
      SutraBoundaries := ScreenObjects[index].ScreenObject.SutraBoundaries;
      ABoundary := SutraBoundaries.GeneralFlowBoundary;
      if ClearAll then
      begin
        ABoundary.Values.Clear;
      end
      else if SetAll or ABoundary.Used then
      begin
        BoundaryList.Add(ABoundary);
        LocalScreenObjects.Add(ScreenObjects[index].ScreenObject);
      end;
    end;

    for index := 0 to BoundaryList.Count - 1 do
    begin
      ABoundary := BoundaryList[index];
      BoundValues := ABoundary.Values as TSutraGeneralFlowCollection;

      if comboSchedule.ItemIndex > 0 then
      begin
        BoundValues.ScheduleName := AnsiString(comboSchedule.Text);
      end
      else
      begin
        BoundValues.ScheduleName := '';
      end;

      SetBoundaryValues(BoundValues);
    end;

  finally
    BoundaryList.Free;
    LocalScreenObjects.Free;
  end;
end;

function TframeSutraGeneralizedFlowBoundary.UsedColumn: Integer;
begin
  result := Ord(gfcUsed);
end;

end.