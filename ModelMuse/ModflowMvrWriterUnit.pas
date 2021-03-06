unit ModflowMvrWriterUnit;

interface

uses
  CustomModflowWriterUnit, ModflowMvrUnit, GoPhastTypes,
  System.Generics.Collections, PhastModelUnit, ModflowCellUnit, System.Classes,
  ModflowPackageSelectionUnit, ScreenObjectUnit, ModflowBoundaryUnit,
  OrderedCollectionUnit, System.Hash, System.Generics.Defaults,
  ModflowBoundaryDisplayUnit;

type
  TMvrSource = record
    Key: TMvrRegisterKey;
    SourcePackage: TSourcePackageChoice;
    Receivers: TReceiverCollection;
    MvrTypes: TMvrTypeArray;
    MvrRates: TOneDRealArray;
    // @name is only used when the receiver is a stream and
    // @link(TSfrReceiverChoice) is @link(TSfrReceiverChoice.srcNearest).
    Cell: TCellLocation;
  end;

  TMvrSources = TList<TMvrSource>;

  TMvrReceiverKey = record
    StressPeriod: Integer;
    ScreenObject: TObject;
    ReceiverPackage: TReceiverPackageChoice;
  end;

  TMvrReceiverValues = record
    // @name is the number of the receiver in its respective package and stress
    // period starting with 1. For the stream package, it is ithe number of
    // the first reach defined by the object.
    Index: Integer;
    // @name is only used for streams.
    StreamCells: TCellLocationArray;
    // @name is only used for UZF boundaries.
    UzfCells: TOneDIntegerArray;
  end;

  TMvrReceiver = record
    ReceiverValues: TMvrReceiverValues;
    ReceiverKey: TMvrReceiverKey;
  end;

  TMvrSourceKeyComparer = class(TEqualityComparer<TMvrSourceKey>)
    function Equals(const Left, Right: TMvrSourceKey): Boolean; override;
    function GetHashCode(const Value: TMvrSourceKey): Integer; override;
  end;

  TMvrSourceCellDictionary = TDictionary<TMvrSourceKey, TMvrSourceCell>;

  TMvrReceiverKeyComparer = class(TEqualityComparer<TMvrReceiverKey>)
    function Equals(const Left, Right: TMvrReceiverKey): Boolean; override;
    function GetHashCode(const Value: TMvrReceiverKey): Integer; override;
  end;

  TModflowMvrWriter = class(TCustomParameterTransientWriter)
  private
  const
    Abbreviation = 'MVR6';
  var
    FReceiverDictionary: TDictionary<TMvrReceiverKey, TMvrReceiverValues>;
    FSourceLists: TObjectList<TMvrSources>;
    FSourceCellDictionaries: TObjectList<TMvrSourceCellDictionary>;
    FNameOfFile: String;
    FUsedPackages: TSourcePackageChoices;
    function ShouldEvaluate: Boolean;
    procedure WriteOptions;
    procedure WriteDimensions;
    procedure WritePackages;
    procedure WriteMvrStressPeriods;
    function GetMaxMvr: Integer;
  protected
    class function Extension: string; override;
    function Package: TModflowPackageSelection; override;
    function CellType: TValueCellType; override;
    function GetBoundary(ScreenObject: TScreenObject): TModflowBoundary;
      override;
    procedure WriteStressPeriods(const VariableIdentifiers, DataSetIdentifier,
      DS5, D7PNameIname, D7PName: string); override;
    function ParameterType: TParameterType; override;
    procedure WriteParameterCells(CellList: TValueCellList; NLST: Integer;
      const VariableIdentifiers, DataSetIdentifier: string;
      AssignmentMethod: TUpdateMethod;
      MultiplierArrayNames: TTransientMultCollection;
      ZoneArrayNames: TTransientZoneCollection); override;
    procedure WriteParameterDefinitions(const DS3, DS3Instances, DS4A,
      DataSetIdentifier, VariableIdentifiers, ErrorRoot: string;
      AssignmentMethod: TUpdateMethod;
      MultiplierArrayNames: TTransientMultCollection;
      ZoneArrayNames: TTransientZoneCollection); override;
  public
    Constructor Create(AModel: TCustomModel; EvaluationType: TEvaluationType); override;
    destructor Destroy; override;
    procedure AddMvrSource(RegisterKey: TMvrRegisterKey);
    procedure AddMvrReceiver(MvrReceiver: TMvrReceiver);
    procedure Evaluate; override;
    procedure WriteFile(const AFileName: string);
    property UsedPackages: TSourcePackageChoices read FUsedPackages;
    procedure UpdateDisplay(TimeLists: TModflowBoundListOfTimeLists);
  end;

implementation

uses
  frmProgressUnit, System.SysUtils, frmErrorsAndWarningsUnit, Vcl.Forms,
  FastGEO, ModflowIrregularMeshUnit, AbstractGridUnit, System.Math;

resourcestring
  StrWritingMVROptions = 'Writing MVR Options';
  StrWritingMVRDimensio = 'Writing MVR Dimensions';
  StrWritingMVRPackages = 'Writing MVR Packages';
  StrWritingMVRStressP = 'Writing MVR Stress Periods';
  StrReceiverNotFound = 'Receiver not found';
  StrSourceObject0s = 'Source object: %0:s.';



{ TModflowMvrWriter }

procedure TModflowMvrWriter.AddMvrReceiver(MvrReceiver: TMvrReceiver);
begin
  if not ShouldEvaluate then
  begin
    Exit
  end;
  if not FReceiverDictionary.ContainsKey(MvrReceiver.ReceiverKey) then
  begin
    FReceiverDictionary.Add(MvrReceiver.ReceiverKey, MvrReceiver.ReceiverValues);
  end;
end;

procedure TModflowMvrWriter.AddMvrSource(RegisterKey: TMvrRegisterKey);
var
  ScreenObject: TScreenObject;
  MvrSourceCell: TMvrSourceCell;
  MvrSource: TMvrSource;
begin
  if not ShouldEvaluate then
  begin
    Exit
  end;
  ScreenObject := RegisterKey.SourceKey.ScreenObject as TScreenObject;
//  RegisterKey.MvrIndex := MvrSource.MvrIndex;

  MvrSource.Key := RegisterKey;
  MvrSource.SourcePackage := ScreenObject.ModflowMvr.SourcePackageChoice;
  MvrSource.Receivers := ScreenObject.ModflowMvr.Receivers;
  Assert(RegisterKey.StressPeriod >= 0);
  Assert(RegisterKey.StressPeriod < FSourceCellDictionaries.Count);
  MvrSourceCell := FSourceCellDictionaries[RegisterKey.StressPeriod][RegisterKey.SourceKey];
  MvrSource.MvrTypes := MvrSourceCell.Values.MvrTypes;
  MvrSource.MvrRates := MvrSourceCell.Values.Values   ;
  MvrSource.Cell := MvrSourceCell.Values.Cell;

  Assert(MvrSource.Receivers.Count = Length(MvrSource.MvrTypes));
  Assert(MvrSource.Receivers.Count = Length(MvrSource.MvrRates));
  Assert(RegisterKey.StressPeriod < FSourceLists.Count);
  FSourceLists[RegisterKey.StressPeriod].Add(MvrSource);
end;

function TModflowMvrWriter.CellType: TValueCellType;
begin
  result := TMvrSourceCell;
end;

constructor TModflowMvrWriter.Create(AModel: TCustomModel;
  EvaluationType: TEvaluationType);
var
  StressPeriodIndex: Integer;
  ReceiverComparer: IEqualityComparer<TMvrReceiverKey>;
  SourceComparer: IEqualityComparer<TMvrSourceKey>;
begin
  inherited;
  ReceiverComparer := TMvrReceiverKeyComparer.Create;
  SourceComparer := TMvrSourceKeyComparer.Create;

  FReceiverDictionary := TDictionary<TMvrReceiverKey, TMvrReceiverValues>.
    Create(ReceiverComparer);

  FSourceLists := TObjectList<TMvrSources>.Create;
  FSourceLists.Capacity := AModel.ModflowFullStressPeriods.Count;

  FSourceCellDictionaries := TObjectList<TMvrSourceCellDictionary>.Create;
  FSourceCellDictionaries.Capacity := AModel.ModflowFullStressPeriods.Count;
  for StressPeriodIndex := 0 to FSourceLists.Capacity - 1 do
  begin
    FSourceLists.Add(TMvrSources.Create);
    FSourceCellDictionaries.Add(TMvrSourceCellDictionary.Create(SourceComparer));
  end;
end;

destructor TModflowMvrWriter.Destroy;
begin
  FReceiverDictionary.Free;
  FSourceLists.Free;
  FSourceCellDictionaries.Free;
  inherited;
end;

procedure TModflowMvrWriter.Evaluate;
var
  StressPeriodIndex: Integer;
  AList: TValueCellList;
  MvrSourceDictionary: TMvrSourceCellDictionary;
  SourceKey: TMvrSourceKey;
  CellIndex: Integer;
  ACell: TMvrSourceCell;
  ScreenObjectIndex: Integer;
  AScreenObject: TScreenObject;
  MvrBound: TMvrBoundary;
  ReceiverIndex: Integer;
  ReceiverItem: TReceiverItem;
begin
  if not ShouldEvaluate then
  begin
    Exit
  end;
  inherited;
  for StressPeriodIndex := 0 to Values.Count - 1 do
  begin
    AList := Values[StressPeriodIndex];
    MvrSourceDictionary := FSourceCellDictionaries[StressPeriodIndex];
    for CellIndex := 0 to AList.Count - 1 do
    begin
      ACell := AList[CellIndex] as TMvrSourceCell;
      Assert(ACell.ScreenObject <> nil);
      SourceKey.MvrIndex := ACell.MvrIndex;
      SourceKey.ScreenObject := ACell.ScreenObject;
      MvrSourceDictionary.Add(SourceKey, ACell);
    end;
  end;

  FUsedPackages := [];
  for ScreenObjectIndex := 0 to Model.ScreenObjectCount - 1 do
  begin
    AScreenObject := Model.ScreenObjects[ScreenObjectIndex];
    if AScreenObject.Deleted then
    begin
      Continue;
    end;

    MvrBound := AScreenObject.ModflowMvr;
    if (MvrBound = nil) or not MvrBound.Used then
    begin
      Continue;
    end;

    Include(FUsedPackages, MvrBound.SourcePackageChoice);
    for ReceiverIndex := 0 to MvrBound.Receivers.Count - 1 do
    begin
      ReceiverItem := MvrBound.Receivers[ReceiverIndex];
      case ReceiverItem.ReceiverPackage of
        rpcLak:
          begin
            Include(FUsedPackages, spcLak);
          end;
        rpcMaw:
          begin
            Include(FUsedPackages, spcMaw);
          end;
        rpcSfr:
          begin
            Include(FUsedPackages, spcSfr);
          end;
        rpcUzf:
          begin
            Include(FUsedPackages, spcUzf);
          end;
        else
          Assert(False);
      end;
    end;
  end;
end;

class function TModflowMvrWriter.Extension: string;
begin
  result := '.mvr';
end;

function TModflowMvrWriter.GetBoundary(
  ScreenObject: TScreenObject): TModflowBoundary;
begin
  result := ScreenObject.ModflowMvr;
end;

function TModflowMvrWriter.GetMaxMvr: Integer;
var
  StressPeriodIndex: Integer;
  SourceList: TMvrSources;
  SourceIndex: Integer;
  ASource: TMvrSource;
  MaxForStressPeriod: Integer;
  ReceiverIndex: Integer;
  ReceiverItem: TReceiverItem;
  ReceiverKey: TMvrReceiverKey;
  ReceiverValues: TMvrReceiverValues;
  SourceScreenObject: TScreenObject;
begin
  result := 0;
  for StressPeriodIndex := 0 to FSourceLists.Count - 1 do
  begin
    ReceiverKey.StressPeriod := StressPeriodIndex;
    MaxForStressPeriod := 0;
    SourceList := FSourceLists[StressPeriodIndex];
    for SourceIndex := 0 to SourceList.Count - 1 do
    begin
      ASource := SourceList[SourceIndex];

      for ReceiverIndex := 0 to ASource.Receivers.Count - 1 do
      begin
        ReceiverItem := ASource.Receivers[ReceiverIndex];
        ReceiverKey.ReceiverPackage := ReceiverItem.ReceiverPackage;
        ReceiverKey.ScreenObject := ReceiverItem.ReceiverObject;

        if FReceiverDictionary.ContainsKey(ReceiverKey) then
        begin
          ReceiverValues := FReceiverDictionary[ReceiverKey];
        end
        else
        begin
          SourceScreenObject := ASource.Key.SourceKey.ScreenObject as TScreenObject;
          frmErrorsAndWarnings.AddError(Model, StrReceiverNotFound,
           Format(StrSourceObject0s, [SourceScreenObject.Name]),
           SourceScreenObject);
          Continue;
        end;

        if ReceiverItem.ReceiverPackage = rpcUzf then
        begin
          Inc(MaxForStressPeriod, Length(ReceiverValues.UzfCells));
        end
        else
        begin
          Inc(MaxForStressPeriod);
        end;
      end;

    end;
    result := Max(result, MaxForStressPeriod);
  end;
end;

function TModflowMvrWriter.Package: TModflowPackageSelection;
begin
  result := Model.ModflowPackages.MvrPackage;
end;

function TModflowMvrWriter.ParameterType: TParameterType;
begin
  result := ptUndefined;
end;

function TModflowMvrWriter.ShouldEvaluate: Boolean;
begin
  result := False;
  if not Package.IsSelected then
  begin
    Exit
  end;
  if Model.PackageGeneratedExternally(Abbreviation) then
  begin
    Exit;
  end;
  result := True;
end;

procedure TModflowMvrWriter.UpdateDisplay(
  TimeLists: TModflowBoundListOfTimeLists);
var
  StressPeriodIndex: Integer;
  MrvCell: TMvrSourceCell;
  ReceiverIndex: Integer;
  MvrTimes: TModflowBoundaryDisplayTimeList;
  MvrArray: TModflowBoundaryDisplayDataArray;
  TimeListIndex: Integer;
  DisplayTimeList: TModflowBoundaryDisplayTimeList;
  TimeIndex: Integer;
  DataArray: TModflowBoundaryDisplayDataArray;
  AList: TValueCellList;
  CellIndex: Integer;
begin
  if not Package.IsSelected then
  begin
    UpdateNotUsedDisplay(TimeLists);
    Exit;
  end;

  Evaluate;

  MvrTimes := TimeLists[0];

  for StressPeriodIndex := 0 to Values.Count - 1 do
  begin
    AList := Values[StressPeriodIndex];
    MvrArray := MvrTimes[StressPeriodIndex]
      as TModflowBoundaryDisplayDataArray;
    for CellIndex := 0 to AList.Count - 1 do
    begin
      MrvCell := AList[CellIndex] as TMvrSourceCell;
      for ReceiverIndex := 0 to MrvCell.MvrValueCount - 1 do
      begin
        MvrArray.AddDataValue(MrvCell.ValueAnnotations[ReceiverIndex],
          MrvCell.MvrValues[ReceiverIndex],
          MrvCell.Column, MrvCell.Row, MrvCell.Layer);
      end;
    end;
  end;

  for TimeListIndex := 0 to TimeLists.Count - 1 do
  begin
    DisplayTimeList := TimeLists[TimeListIndex];
    for TimeIndex := 0 to DisplayTimeList.Count - 1 do
    begin
      DataArray := DisplayTimeList[TimeIndex]
        as TModflowBoundaryDisplayDataArray;
      DataArray.UpToDate := True;
    end;
    DisplayTimeList.SetUpToDate(True);
  end;

end;

procedure TModflowMvrWriter.WriteDimensions;
var
  PackageChoice: TSourcePackageChoice;
  maxpackages: Integer;
begin
  WriteBeginDimensions;

  WriteString('    MAXMVR ');
  WriteInteger(GetMaxMvr);
  NewLine;

  maxpackages := 0;
  for PackageChoice in FUsedPackages do
  begin
    Inc(maxpackages);
  end;
  WriteString('    MAXPACKAGES ');
  WriteInteger(maxpackages);
  NewLine;

  WriteEndDimensions
end;

procedure TModflowMvrWriter.WriteFile(const AFileName: string);
begin
  if not ShouldEvaluate then
  begin
    Exit
  end;

  FNameOfFile := FileName(AFileName);
  WriteToNameFile(Abbreviation, -1, FNameOfFile, foInput, Model);
  frmErrorsAndWarnings.BeginUpdate;
  try
    Application.ProcessMessages;
    if not frmProgressMM.ShouldContinue then
    begin
      Exit;
    end;
    OpenFile(FileName(FNameOfFile));
    try
      WriteDataSet0;

      frmProgressMM.AddMessage(StrWritingMVROptions);
      WriteOptions;
      Application.ProcessMessages;
      if not frmProgressMM.ShouldContinue then
      begin
        Exit;
      end;

      frmProgressMM.AddMessage(StrWritingMVRDimensio);
      WriteDimensions;
      Application.ProcessMessages;
      if not frmProgressMM.ShouldContinue then
      begin
        Exit;
      end;

      frmProgressMM.AddMessage(StrWritingMVRPackages);
      WritePackages;
      Application.ProcessMessages;
      if not frmProgressMM.ShouldContinue then
      begin
        Exit;
      end;

      frmProgressMM.AddMessage(StrWritingMVRStressP);
      WriteMvrStressPeriods;
      Application.ProcessMessages;
      if not frmProgressMM.ShouldContinue then
      begin
        Exit;
      end;
    finally
      CloseFile
    end;

  finally
    frmErrorsAndWarnings.EndUpdate;
  end;
end;

procedure TModflowMvrWriter.WriteMvrStressPeriods;
var
  StressPeriodIndex: Integer;
  SourceList: TMvrSources;
  SourceIndex: Integer;
  ASource: TMvrSource;
  ReceiverKey: TMvrReceiverKey;
  ReceiverItem: TReceiverItem;
  ReceiverValues: TMvrReceiverValues;
  MvrSourceDictionary: TMvrSourceCellDictionary;
  MrvCell: TMvrSourceCell;
  ReceiverIndex: Integer;
  AColumn: Integer;
  ARow: Integer;
  DisvGrid: TModflowDisvGrid;
  Grid: TCustomModelGrid;
  MinIndex: Integer;
  SourceLocation: TPoint2D;
  ReceiverLocation: TPoint2D;
  MinDistance: double;
  SfrCellIndex: Integer;
  TestDistance: TFloat;
  SourceScreenObject: TScreenObject;
  InnerReceiverIndex: Integer;
  ReceiverCount: Integer;
  function GetLocation(ACol, ARow: Integer): TPoint2D;
  begin
    if Grid <> nil then
    begin
      result := Grid.TwoDElementCenter(ACol, ARow)
    end
    else
    begin
      Assert(DisvGrid <> nil);
      result := DisvGrid.TwoDGrid.Cells[ACol].Location;
    end;
  end;
begin
  if Model.DisvUsed then
  begin
    DisvGrid := Model.DisvGrid;
    Grid := nil;
  end
  else
  begin
    Grid := Model.Grid;
    DisvGrid := nil;
  end;
  for StressPeriodIndex := 0 to FSourceLists.Count - 1 do
  begin
    SourceList := FSourceLists[StressPeriodIndex];
    if SourceList.Count > 0 then
    begin
      MvrSourceDictionary := FSourceCellDictionaries[StressPeriodIndex];

      ReceiverKey.StressPeriod := StressPeriodIndex;
      WriteBeginPeriod(StressPeriodIndex);

      for SourceIndex := 0 to SourceList.Count - 1 do
      begin
        ASource := SourceList[SourceIndex];
        MrvCell := MvrSourceDictionary[ASource.Key.SourceKey];

        for ReceiverIndex := 0 to ASource.Receivers.Count - 1 do
        begin
          ReceiverItem := ASource.Receivers[ReceiverIndex];
          ReceiverKey.ReceiverPackage := ReceiverItem.ReceiverPackage;
          ReceiverKey.ScreenObject := ReceiverItem.ReceiverObject;

          if FReceiverDictionary.ContainsKey(ReceiverKey) then
          begin
            ReceiverValues := FReceiverDictionary[ReceiverKey];
          end
          else
          begin
            SourceScreenObject := ASource.Key.SourceKey.ScreenObject as TScreenObject;
            frmErrorsAndWarnings.AddError(Model, StrReceiverNotFound,
             Format(StrSourceObject0s, [SourceScreenObject.Name]),
             SourceScreenObject);
            Continue;
          end;

          if ReceiverItem.ReceiverPackage = rpcUzf then
          begin
            ReceiverCount := Length(ReceiverValues.UzfCells);
          end
          else
          begin
            ReceiverCount := 1;
          end;

          for InnerReceiverIndex := 0 to ReceiverCount-1 do
          begin
            case ASource.SourcePackage of
              spcWel:
                begin
                  WriteString('  WEL-1');
                end;
              spcDrn:
                begin
                  WriteString('  DRN-1');
                end;
              spcRiv:
                begin
                  WriteString('  RIV-1');
                end;
              spcGhb:
                begin
                  WriteString('  GHB-1');
                end;
              spcLak:
                begin
                  WriteString('  LAK-1');
                end;
              spcMaw:
                begin
                  WriteString('  MAW-1');
                end;
              spcSfr:
                begin
                  WriteString('  SFR-1');
                end;
              spcUzf:
                begin
                  WriteString('  UZF-1');
                end;
              else Assert(False);
            end;

            WriteInteger(ASource.Key.Index);

            case ReceiverItem.ReceiverPackage of
              rpcLak:
                begin
                  WriteString(' LAK-1');
                end;
              rpcMaw:
                begin
                  WriteString(' MAW-1');
                end;
              rpcSfr:
                begin
                  WriteString(' SFR-1');
                end;
              rpcUZF:
                begin
                  WriteString(' UZF-1');
                end;
            end;

            if (ReceiverItem.ReceiverPackage = rpcSfr)
              and (ReceiverItem.SfrReceiverChoice = srcNearest) then
            begin
              AColumn := MrvCell.Column;
              ARow := MrvCell.Row;
              SourceLocation := GetLocation(AColumn, ARow);

              Assert(Length(ReceiverValues.StreamCells) > 0);
              ReceiverLocation := GetLocation(
                ReceiverValues.StreamCells[0].Column,
                ReceiverValues.StreamCells[0].Row);
              MinIndex := 0;
              MinDistance := Distance(SourceLocation, ReceiverLocation);

              for SfrCellIndex := 1 to Length(ReceiverValues.StreamCells) - 1 do
              begin
                ReceiverLocation := GetLocation(
                  ReceiverValues.StreamCells[SfrCellIndex].Column,
                  ReceiverValues.StreamCells[SfrCellIndex].Row);
                TestDistance := Distance(SourceLocation, ReceiverLocation);
                if TestDistance < MinDistance then
                begin
                  MinDistance := TestDistance;
                  MinIndex := SfrCellIndex;
                end;
              end;
              WriteInteger(ReceiverValues.Index + MinIndex);
            end
            else if ReceiverItem.ReceiverPackage = rpcUzf then
            begin
              WriteInteger(ReceiverValues.UzfCells[InnerReceiverIndex]);
            end
            else
            begin
              WriteInteger(ReceiverValues.Index);
            end;

            case MrvCell.MvrTypes[ReceiverIndex] of
              mtFactor:
                begin
                  WriteString(' FACTOR   ');
                end;
              mtExcess:
                begin
                  WriteString(' EXCESS   ');
                end;
              mtThreshold:
                begin
                  WriteString(' THRESHOLD');
                end;
              mtUpTo:
                begin
                  WriteString(' UPTO     ');
                end;
              else Assert(False);
            end;

            WriteFloat(MrvCell.MvrValues[ReceiverIndex]);

            NewLine;
          end;
        end;
      end;

      WriteEndPeriod;
    end;
  end;
end;

procedure TModflowMvrWriter.WriteOptions;
var
  MvrPackage: TMvrPackage;
  budgetfile: string;
begin
  WriteBeginOptions;

  PrintListInputOption;
  PrintFlowsOption;

  MvrPackage := Model.ModflowPackages.MvrPackage;
  if MvrPackage.SaveBudgetFile then
  begin
    WriteString('    BUDGET FILEOUT ');
    budgetfile := ChangeFileExt(FNameOfFile, '.mvr_budget');
    Model.AddModelOutputFile(budgetfile);
    budgetfile := ExtractFileName(budgetfile);
    WriteString(budgetfile);
    NewLine;
  end;

  WriteEndOptions
end;

procedure TModflowMvrWriter.WritePackages;
var
  PackageChoice: TSourcePackageChoice;
begin
  WriteString('BEGIN PACKAGES');
  NewLine;

  for PackageChoice in FUsedPackages do
  begin
    case PackageChoice of
      spcWel:
        begin
          WriteString('  WEL-1');
          NewLine
        end;
      spcDrn:
        begin
          WriteString('  DRN-1');
          NewLine
        end;
      spcRiv:
        begin
          WriteString('  RIV-1');
          NewLine
        end;
      spcGhb:
        begin
          WriteString('  GHB-1');
          NewLine
        end;
      spcLak:
        begin
          WriteString('  LAK-1');
          NewLine
        end;
      spcMaw:
        begin
          WriteString('  MAW-1');
          NewLine
        end;
      spcSfr:
        begin
          WriteString('  SFR-1');
          NewLine
        end;
      spcUzf:
        begin
          WriteString('  UZF-1');
          NewLine
        end;
      else Assert(False);
    end;
  end;

  WriteString('END PACKAGES');
  NewLine;

end;

procedure TModflowMvrWriter.WriteParameterCells(CellList: TValueCellList;
  NLST: Integer; const VariableIdentifiers, DataSetIdentifier: string;
  AssignmentMethod: TUpdateMethod;
  MultiplierArrayNames: TTransientMultCollection;
  ZoneArrayNames: TTransientZoneCollection);
begin
  Assert(False);
  inherited;

end;

procedure TModflowMvrWriter.WriteParameterDefinitions(const DS3, DS3Instances,
  DS4A, DataSetIdentifier, VariableIdentifiers, ErrorRoot: string;
  AssignmentMethod: TUpdateMethod;
  MultiplierArrayNames: TTransientMultCollection;
  ZoneArrayNames: TTransientZoneCollection);
begin
  Assert(False);
  inherited;

end;

procedure TModflowMvrWriter.WriteStressPeriods(const VariableIdentifiers,
  DataSetIdentifier, DS5, D7PNameIname, D7PName: string);
begin
  Assert(False);
  inherited;

end;

{ TMvrReceiverKeyComparer }

function TMvrReceiverKeyComparer.Equals(const Left,
  Right: TMvrReceiverKey): Boolean;
begin
  Result := (Left.StressPeriod = Right.StressPeriod)
    and (Left.ScreenObject = Right.ScreenObject)
    and (Left.ReceiverPackage = Right.ReceiverPackage);
end;

function TMvrReceiverKeyComparer.GetHashCode(
  const Value: TMvrReceiverKey): Integer;
begin
  Result := THashBobJenkins.GetHashValue(Value.StressPeriod, SizeOf(Value.StressPeriod), 0);
  Result := THashBobJenkins.GetHashValue(Value.ScreenObject, SizeOf(Value.ScreenObject), Result);
  Result := THashBobJenkins.GetHashValue(Value.ReceiverPackage, SizeOf(Value.ReceiverPackage), Result);
end;

{ TMvrSourceKeyComparer }

function TMvrSourceKeyComparer.Equals(const Left,
  Right: TMvrSourceKey): Boolean;
begin
  Result := (Left.MvrIndex = Right.MvrIndex)
    and (Left.ScreenObject = Right.ScreenObject)
end;

function TMvrSourceKeyComparer.GetHashCode(const Value: TMvrSourceKey): Integer;
begin
  Result := THashBobJenkins.GetHashValue(Value.MvrIndex, SizeOf(Value.MvrIndex), 0);
  Result := THashBobJenkins.GetHashValue(Value.ScreenObject, SizeOf(Value.ScreenObject), Result);
end;

end.
