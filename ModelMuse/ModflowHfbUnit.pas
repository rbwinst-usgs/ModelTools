unit ModflowHfbUnit;

interface

uses ZLib, Classes, Contnrs, SysUtils, RbwParser, GoPhastTypes,
  ModflowBoundaryUnit, SubscriptionUnit, FormulaManagerUnit,
  OrderedCollectionUnit, ModflowCellUnit, RealListUnit;

type
  TAdjustmentMethod = (amNone, amAllEdges, amNearlyParallel);

  THfbRecord = record
    Cell1: TCellLocation;
    Cell2: TCellLocation;
    HydraulicConductivity: double;
    Thickness: double;
    StartingTime: double;
    EndingTime: double;
    HydraulicConductivityAnnotation: string;
    ThicknessAnnotation: string;
    procedure Cache(Comp: TCompressionStream; Strings: TStringList);
    procedure Restore(Decomp: TDecompressionStream; Annotations: TStringList);
    procedure RecordStrings(Strings: TStringList);
  end;

  THfbArray = array of THfbRecord;

  THfbStorage = class(TCustomBoundaryStorage)
  private
    FHfbArray: THfbArray;
    function GetHfbArray: THfbArray;
  protected
    procedure Restore(DecompressionStream: TDecompressionStream; Annotations: TStringList); override;
    procedure Store(Compressor: TCompressionStream); override;
    procedure Clear; override;
  public
    property HfbArray: THfbArray read GetHfbArray;
  end;


  // Transient horizontal flow barrier in MODFLOW 6
  THfbItem = class(TCustomModflowBoundaryItem)
  private
    // See @link(HydraulicConductivityFormula).
    FHydraulicConductivityFormula: TFormulaObject;
    // See @link(ThicknessFormula).
    FThicknessFormula: TFormulaObject;
    function GetHydraulicConductivity: string;
    function GetThickness: string;
    procedure SetHydraulicConductivity(const Value: string);
    procedure SetThickness(const Value: string);
  protected
//    FObserverList: TObserverObjectList;
    procedure AssignObserverEvents(Collection: TCollection); override;
    procedure CreateFormulaObjects; override;
    procedure GetPropertyObserver(Sender: TObject; List: TList); override;
    procedure RemoveFormulaObjects; override;
    // @name returns @true if AnotherItem is a @classname and
    // @link(StartTime) and (EndTime) are the same in the current
    // @classname and in AnotherItem.
    function IsSame(AnotherItem: TOrderedItem): boolean; override;
    function GetBoundaryFormula(Index: integer): string; override;
    procedure SetBoundaryFormula(Index: integer; const Value: string);
      override;
    function BoundaryFormulaCount: integer; override;
  public
    procedure Assign(Source: TPersistent); override;
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    // Descendants of @classname define string properties that are the
    // formulas for the unique features of each boundary condition.
    // @name provides access to those properties without knowing what
    // they are through the virtual abstract methods @link(GetBoundaryFormula)
    // and @link(SetBoundaryFormula).  Descendants must override those
    // methods.  @name is used in
    // @link(TfrmScreenObjectProperties.StoreModflowBoundary
    // TfrmScreenObjectProperties.StoreModflowBoundary) and
    // @link(TfrmScreenObjectProperties.GetModflowBoundary
    // TfrmScreenObjectProperties.GetModflowBoundary).
    // @seealso(TCustomMF_BoundColl)
    property BoundaryFormula[Index: integer]: string read GetBoundaryFormula
      write SetBoundaryFormula;
  published
    property HydraulicConductivity: string read GetHydraulicConductivity
      write SetHydraulicConductivity;
    property Thickness: string read GetThickness write SetThickness;
  end;

  THfbTimeListLink = class(TTimeListsModelLink)
  private
    // @name is used to perform notifications of the Elevations for a series of
    // Drain Boundaries over a series of time intervals.
//    FElevationData: TModflowTimeList;
    // @name is used to perform notifications of the Conductances
    // for a series of
    // Drain Boundaries over a series of time intervals.
//    FConductanceData: TModflowTimeList;
  protected
    procedure CreateTimeLists; override;
  public
    Destructor Destroy; override;
  end;

  // @name represents MODFLOW HFB boundaries
  // for a series of time intervals.
  THfbCollection = class(TCustomMF_ListBoundColl)
  private
    procedure InvalidateHydraulicConductivity(Sender: TObject);
    procedure InvalidateThickness(Sender: TObject);
    function GetItems(Index: Integer): THfbItem;
    procedure SetItems(Index: Integer; const Value: THfbItem);
  protected
    function GetTimeListLinkClass: TTimeListsModelLinkClass; override;
    procedure AssignListCellLocation(BoundaryStorage: TCustomBoundaryStorage;
      ACellList: TObject); override;
    procedure AssignCellList(Expression: TExpression; ACellList: TObject;
      BoundaryStorage: TCustomBoundaryStorage; BoundaryFunctionIndex: integer;
      Variables, DataSets: TList; AModel: TBaseModel; AScreenObject: TObject); override;
    procedure AddSpecificBoundary(AModel: TBaseModel); override;

    // See @link(TCustomNonSpatialBoundColl.ItemClass
    // TCustomNonSpatialBoundColl.ItemClass)
    class function ItemClass: TBoundaryItemClass; override;
    // @name calls inherited @name and then sets the length of
    // the @link(THfbStorage.HfbArray) at ItemIndex in
    // @link(TCustomMF_BoundColl.Boundaries) to BoundaryCount.
    // @SeeAlso(TCustomMF_BoundColl.SetBoundaryStartAndEndTime
    // TCustomMF_BoundColl.SetBoundaryStartAndEndTime)
    procedure SetBoundaryStartAndEndTime(BoundaryCount: Integer;
      Item: TCustomModflowBoundaryItem; ItemIndex: Integer;
      AModel: TBaseModel); override;
    procedure AssignArrayCellValues(DataSets: TList; ItemIndex: Integer;
      AModel: TBaseModel); override;
    function AdjustedFormula(FormulaIndex, ItemIndex: integer): string;
      override;
  public
    function Add: THfbItem;
    property Items[Index: Integer]: THfbItem read GetItems write SetItems; default;
  end;

  THfbBoundary = class(TModflowSteadyBoundary)
  private
    FAdjustmentMethod: TAdjustmentMethod;
    FThicknessFormula: TFormulaObject;
    FHydraulicConductivityFormula: TFormulaObject;
    FParameterName: string;
    FHydraulicConductivityObserver: TObserver;
    FThicknessObserver: TObserver;
    FParameterNameObserver: TObserver;
    FAdjustmentMethodObserver: TObserver;
    FVerticalBoundary: boolean;
    FLayerOffsetFormula: TFormulaObject;
    FLayerOffsetObserver: TObserver;
  private

    // See @link(Values).
    FValues: THfbCollection;

    // See @link(Values).
    procedure SetValues(const Value: THfbCollection);
    procedure SetAdjustmentMethod(const Value: TAdjustmentMethod);
    procedure SetHydraulicConductivity(Value: string);
    procedure SetParameterName(const Value: string);
    procedure SetThickness(const Value: string);
    function GetHydraulicConductivityObserver: TObserver;
    function GetThicknessObserver: TObserver;
    function GetParameterNameObserver: TObserver;
    function GetAdjustmentMethodObserver: TObserver;
    function GetHydraulicConductivity: string;
    function GetThickness: string;
    function GetLayerOffsetFormula: string;
    procedure SetLayerOffsetFormula(const Value: string);
    procedure SetVerticalBoundary(const Value: boolean);
    function GetLayerOffsetObserver: TObserver;
    function GetUsedMf6: Boolean;
  protected
    procedure HandleChangedValue(Observer: TObserver); override;
    function GetUsedObserver: TObserver; override;
    procedure GetPropertyObserver(Sender: TObject; List: TList); override;
    procedure CreateFormulaObjects; override;
    property HydraulicConductivityObserver: TObserver
      read GetHydraulicConductivityObserver;
    property ThicknessObserver: TObserver read GetThicknessObserver;
    property ParameterNameObserver: TObserver read GetParameterNameObserver;
    property AdjustmentMethodObserver: TObserver read GetAdjustmentMethodObserver;
    property LayerOffsetObserver: TObserver read GetLayerOffsetObserver;
    function BoundaryObserverPrefix: string; override;
    procedure CreateObservers; override;
    procedure CreateObserver(ObserverNameRoot: string; var Observer: TObserver;
      Displayer: TObserver); override;
  public
    Procedure Assign(Source: TPersistent); override;
    Constructor Create(Model: TBaseModel; ScreenObject: TObject);
    destructor Destroy; override;
    procedure HandleChangedParameterValue;
    procedure InvalidateDisplay;
    property UsedMf6: Boolean read GetUsedMf6;
    procedure UpdateTimes(Times: TRealList; StartTestTime, EndTestTime: double;
      var StartRangeExtended, EndRangeExtended: boolean; AModel: TBaseModel); virtual;
  published
    property ParameterName: string read FParameterName write SetParameterName;
    property HydraulicConductivityFormula: string read GetHydraulicConductivity
      write SetHydraulicConductivity;
    property ThicknessFormula: string read GetThickness write SetThickness;
    property AdjustmentMethod: TAdjustmentMethod read FAdjustmentMethod
      write SetAdjustmentMethod;
    property VerticalBoundary: boolean read FVerticalBoundary write SetVerticalBoundary;
    property LayerOffsetFormula: string read GetLayerOffsetFormula
      write SetLayerOffsetFormula;
    property Values: THfbCollection read FValues write SetValues;
  end;

implementation

uses PhastModelUnit, ScreenObjectUnit, frmGoPhastUnit, frmErrorsAndWarningsUnit,
  GIS_Functions;

resourcestring
  StrHFBThicknessSetTo = 'HFB Thickness set to 0 because of a math error.';
  StrHFBHydraulicConduc = 'HFB hydraulic conductivity set to 0 because of a ' +
  'math error.';

const
  ThicknessPosition = 0;
  HydraulicConductivityPosition = 1;
  LayerOffsetPosition = 2;

//procedure RemoveHfbModflowBoundarySubscription(Sender: TObject; Subject: TObject;
//  const AName: string);
//begin
//  (Subject as THfbBoundary).RemoveSubscription(Sender, AName);
//end;
//
//procedure RestoreHfbModflowBoundarySubscription(Sender: TObject; Subject: TObject;
//  const AName: string);
//begin
//  (Subject as THfbBoundary).RestoreSubscription(Sender, AName);
//end;


{ THfbBoundary }

procedure THfbBoundary.Assign(Source: TPersistent);
var
  SourecHFB: THfbBoundary;
begin
  if Source is THfbBoundary then
  begin
    SourecHFB := THfbBoundary(Source);
    ParameterName := SourecHFB.ParameterName;
    HydraulicConductivityFormula := SourecHFB.HydraulicConductivityFormula;
    ThicknessFormula := SourecHFB.ThicknessFormula;
    AdjustmentMethod := SourecHFB.AdjustmentMethod;
    VerticalBoundary := SourecHFB.VerticalBoundary;
    LayerOffsetFormula := SourecHFB.LayerOffsetFormula;
    IsUsed := SourecHFB.IsUsed;
    Values := SourecHFB.Values;
  end
  else
  begin
    inherited;
  end;
end;

function THfbBoundary.BoundaryObserverPrefix: string;
begin
  result := 'HfbBoundary_';
end;

constructor THfbBoundary.Create(Model: TBaseModel; ScreenObject: TObject);
begin
  inherited;

  ThicknessFormula := '1';
  HydraulicConductivityFormula := '1e-8';
  LayerOffsetFormula := '0';
  
  FValues := THfbCollection.Create(self, Model, ScreenObject);
end;

procedure THfbBoundary.CreateFormulaObjects;
begin
  FThicknessFormula := CreateFormulaObjectBlocks(dso3D);
  FHydraulicConductivityFormula := CreateFormulaObjectBlocks(dso3D);
  FLayerOffsetFormula := CreateFormulaObjectBlocks(dso3D);
end;

destructor THfbBoundary.Destroy;
begin
  FValues.Free;
  HydraulicConductivityFormula := '0';
  ThicknessFormula := '0';
  LayerOffsetFormula := '0';

  FParameterNameObserver.Free;
  FAdjustmentMethodObserver.Free;
  inherited;
end;

function THfbBoundary.GetAdjustmentMethodObserver: TObserver;
var
  Model: TPhastModel;
  Observer: TObserver;
begin
  if FAdjustmentMethodObserver = nil then
  begin
    if ParentModel <> nil then
    begin
      Model := ParentModel as TPhastModel;
      Observer := Model.HfbDisplayer;
    end
    else
    begin
      Observer := nil;
    end;
    CreateObserver('HFB_AdjustmentMethod_', FAdjustmentMethodObserver,
      Observer);
//    FObserverList.Add(FAdjustmentMethodObserver);
  end;
  result := FAdjustmentMethodObserver;
end;

function THfbBoundary.GetHydraulicConductivity: string;
begin
  Result := FHydraulicConductivityFormula.Formula;
  if ScreenObject <> nil then
  begin
    ResetItemObserver(HydraulicConductivityPosition);
  end;
end;

function THfbBoundary.GetHydraulicConductivityObserver: TObserver;
var
  Model: TPhastModel;
  Observer: TObserver;
begin
  if FHydraulicConductivityObserver = nil then
  begin
    if ParentModel <> nil then
    begin
      Model := ParentModel as TPhastModel;
      Observer := Model.HfbDisplayer;
    end
    else
    begin
      Observer := nil;
    end;
    CreateObserver('HFB_HydraulicConductivity_',
      FHydraulicConductivityObserver, Observer);
//    FObserverList.Add(FHydraulicConductivityObserver);
  end;
  result := FHydraulicConductivityObserver;
end;

function THfbBoundary.GetLayerOffsetFormula: string;
begin
  Result := FLayerOffsetFormula.Formula;
  if ScreenObject <> nil then
  begin
    ResetItemObserver(LayerOffsetPosition);
  end;
end;

function THfbBoundary.GetLayerOffsetObserver: TObserver;
var
  Model: TPhastModel;
  Observer: TObserver;
begin
  if FLayerOffsetObserver = nil then
  begin
    if ParentModel <> nil then
    begin
      Model := ParentModel as TPhastModel;
      Observer := Model.HfbDisplayer;
    end
    else
    begin
      Observer := nil;
    end;
    CreateObserver('HFB_Layer_Offset_', FLayerOffsetObserver, Observer);
//    FObserverList.Add(FLayerOffsetObserver);
  end;
  result := FLayerOffsetObserver;
end;

function THfbBoundary.GetParameterNameObserver: TObserver;
var
  Model: TPhastModel;
  Observer: TObserver;
begin
  if FParameterNameObserver = nil then
  begin
    if ParentModel <> nil then
    begin
      Model := ParentModel as TPhastModel;
      Observer := Model.HfbDisplayer;
    end
    else
    begin
      Observer := nil;
    end;
    CreateObserver('HFB_ParameterName_', FParameterNameObserver, Observer);
//    FObserverList.Add(FParameterNameObserver);
  end;
  result := FParameterNameObserver;
end;

procedure THfbBoundary.GetPropertyObserver(Sender: TObject; List: TList);
begin
  if Sender = FThicknessFormula then
  begin
    List.Add(FObserverList[ThicknessPosition]);
  end;
  if Sender = FHydraulicConductivityFormula then
  begin
    List.Add(FObserverList[HydraulicConductivityPosition]);
  end;
  if Sender = FLayerOffsetFormula then
  begin
    List.Add(FObserverList[LayerOffsetPosition]);
  end;
end;

function THfbBoundary.GetThickness: string;
begin
  Result := FThicknessFormula.Formula;
  if ScreenObject <> nil then
  begin
    ResetItemObserver(ThicknessPosition);
  end;
end;

function THfbBoundary.GetThicknessObserver: TObserver;
var
  Model: TPhastModel;
  Observer: TObserver;
begin
  if FThicknessObserver = nil then
  begin
    if ParentModel <> nil then
    begin
      Model := ParentModel as TPhastModel;
      Observer := Model.HfbDisplayer;
    end
    else
    begin
      Observer := nil;
    end;
    CreateObserver('HFB_Thickness_', FThicknessObserver, Observer);
//    FObserverList.Add(FThicknessObserver);
  end;
  result := FThicknessObserver;
end;

function THfbBoundary.GetUsedMf6: Boolean;
begin
  result := Values.Count > 0;
end;

function THfbBoundary.GetUsedObserver: TObserver;
var
  Model: TPhastModel;
  Observer: TObserver;
begin
  if FUsedObserver = nil then
  begin
    if ParentModel <> nil then
    begin
      Model := ParentModel as TPhastModel;
      Observer := Model.HfbDisplayer;
    end
    else
    begin
      Observer := nil;
    end;
    CreateObserver('HFB_Used_', FUsedObserver, Observer);
//    FObserverList.Add(FUsedObserver);
  end;
  result := FUsedObserver;
end;

procedure THfbBoundary.SetAdjustmentMethod(const Value: TAdjustmentMethod);
var
  ScreenObject: TScreenObject;
begin
  if FAdjustmentMethod <> Value then
  begin
    if FScreenObject <> nil then
    begin
      ScreenObject := FScreenObject as TScreenObject;
      if ScreenObject.CanInvalidateModel then
      begin
        HandleChangedValue(AdjustmentMethodObserver);
      end;
    end;
    FAdjustmentMethod := Value;
    InvalidateModel;
  end;
end;

procedure THfbBoundary.SetHydraulicConductivity(Value: string);
begin
  UpdateFormulaBlocks(Value, HydraulicConductivityPosition, FHydraulicConductivityFormula);
end;

procedure THfbBoundary.SetLayerOffsetFormula(const Value: string);
begin
  UpdateFormulaBlocks(Value, LayerOffsetPosition, FLayerOffsetFormula);
end;

procedure THfbBoundary.SetParameterName(const Value: string);
var
  ScreenObject: TScreenObject;
begin
  if FParameterName <> Value then
  begin
    ScreenObject := FScreenObject as TScreenObject;
    if FScreenObject <> nil then
    begin
      if ScreenObject.CanInvalidateModel then
      begin
        HandleChangedValue(ParameterNameObserver);
      end;
    end;

    FParameterName := Value;
    InvalidateModel;
  end;
end;

procedure THfbBoundary.SetThickness(const Value: string);
begin
  UpdateFormulaBlocks(Value, ThicknessPosition, FThicknessFormula);
end;

procedure THfbBoundary.SetValues(const Value: THfbCollection);
begin
  FValues.Assign(Value);
end;

procedure THfbBoundary.SetVerticalBoundary(const Value: boolean);
begin
  if FVerticalBoundary <> Value then
  begin
    FVerticalBoundary := Value;
    InvalidateModel;
  end;
end;

procedure THfbBoundary.UpdateTimes(Times: TRealList; StartTestTime,
  EndTestTime: double; var StartRangeExtended, EndRangeExtended: boolean;
  AModel: TBaseModel);
begin
  AddBoundaryTimes(Values, Times, StartTestTime, EndTestTime,
    StartRangeExtended, EndRangeExtended);
end;

procedure THfbBoundary.HandleChangedValue(Observer: TObserver);
var
  Model: TPhastModel;
  ChildIndex: Integer;
begin
  Model := ParentModel as TPhastModel;
  if not (csDestroying in Model.ComponentState)
    and not Model.Clearing then
  begin
    Observer.UpToDate := True;
    Observer.UpToDate := False;
    Model.HfbDisplayer.Invalidate;
    for ChildIndex := 0 to Model.ChildModels.Count - 1 do
    begin
      Model.ChildModels[ChildIndex].ChildModel.HfbDisplayer.Invalidate;
    end;
    Observer.UpToDate := True;
  end;
end;

procedure THfbBoundary.InvalidateDisplay;
begin
  if Used and (ParentModel <> nil) then
  begin
    HandleChangedValue(HydraulicConductivityObserver);
    HandleChangedValue(ThicknessObserver);
    HandleChangedValue(LayerOffsetObserver);
  end;
end;

procedure THfbBoundary.CreateObserver(ObserverNameRoot: string;
  var Observer: TObserver; Displayer: TObserver);
var
  ScreenObject: TScreenObject;
  Model: TPhastModel;
begin
  inherited;
  ScreenObject := FScreenObject as TScreenObject;
  if ScreenObject.CanInvalidateModel then
  begin
    Model := ParentModel as TPhastModel;
    Assert(Model <> nil);
    Model.HfbDisplayer.Invalidate;
  end;
end;

procedure THfbBoundary.CreateObservers;
begin
  if ScreenObject <> nil then
  begin
    FObserverList.Add(ThicknessObserver);
    FObserverList.Add(HydraulicConductivityObserver);
    FObserverList.Add(LayerOffsetObserver);
  end;
end;


procedure THfbBoundary.HandleChangedParameterValue;
var
  ScreenObject: TScreenObject;
begin
  ScreenObject := FScreenObject as TScreenObject;
  if ScreenObject.CanInvalidateModel then
  begin
    HandleChangedValue(ParameterNameObserver);
  end;
end;

{ THfbItem }

procedure THfbItem.Assign(Source: TPersistent);
var
  HfbItem: THfbItem;
begin
  // if Assign is updated, update IsSame too.
  if Source is THfbItem then
  begin
    HfbItem := THfbItem(Source);
    HydraulicConductivity := HfbItem.HydraulicConductivity;
    Thickness := HfbItem.Thickness;
  end;
  inherited;
end;

procedure THfbItem.AssignObserverEvents(Collection: TCollection);
begin
  inherited;

end;

function THfbItem.BoundaryFormulaCount: integer;
begin
  result := 2;
end;

constructor THfbItem.Create(Collection: TCollection);
var
  Index: integer;
  Observer: TObserver;
  LocalScreenObject: TScreenObject;
begin
  inherited;
  OnRemoveSubscription := GlobalRemoveModflowBoundaryItemSubscription;
  OnRestoreSubscription := GlobalRestoreModflowBoundaryItemSubscription;

  CreateFormulaObjects;
//  FObserverList := TObserverObjectList.Create;
  for Index := 0 to BoundaryFormulaCount - 1 do
  begin
    Observer := TObserver.Create(nil);
    FObserverList.Add(Observer);
    LocalScreenObject := ScreenObject as TScreenObject;
    if (LocalScreenObject <> nil) and LocalScreenObject.CanInvalidateModel then
    begin
      LocalScreenObject.TalksTo(Observer);
    end;
    BoundaryFormula[Index] := '0';
  end;
  AssignObserverEvents(Collection);
end;

procedure THfbItem.CreateFormulaObjects;
begin
  FThicknessFormula := CreateFormulaObject(dso3D);
  FHydraulicConductivityFormula := CreateFormulaObject(dso3D);
end;

destructor THfbItem.Destroy;
//var
//  LocalScreenObject: TScreenObject;
//  Observer: TObserver;
//  Index: integer;
//  PhastModel: TPhastModel;
begin
  HydraulicConductivity := '0';
  Thickness := '0';
//  FObserverList.Free;
  inherited;
end;

function THfbItem.GetBoundaryFormula(Index: integer): string;
begin
  case Index of
    ThicknessPosition: result := Thickness;
    HydraulicConductivityPosition: result := HydraulicConductivity;
    else Assert(False);
  end;
end;

function THfbItem.GetHydraulicConductivity: string;
begin
  Result := FHydraulicConductivityFormula.Formula;
  ResetItemObserver(HydraulicConductivityPosition);
end;

procedure THfbItem.GetPropertyObserver(Sender: TObject; List: TList);
begin
  if Sender = FThicknessFormula then
  begin
    List.Add(FObserverList[ThicknessPosition]);
  end;
  if Sender = FHydraulicConductivityFormula then
  begin
    List.Add(FObserverList[HydraulicConductivityPosition]);
  end;
end;

function THfbItem.GetThickness: string;
begin
  Result := FThicknessFormula.Formula;
  ResetItemObserver(ThicknessPosition);
end;

function THfbItem.IsSame(AnotherItem: TOrderedItem): boolean;
var
  OtherHfb: THfbItem;
begin
  result := (AnotherItem is THfbItem) and inherited;
  if result then
  begin
    OtherHfb := THfbItem(AnotherItem);
    result := (HydraulicConductivity = OtherHfb.HydraulicConductivity)
      and (Thickness = OtherHfb.Thickness);
  end;
end;

procedure THfbItem.RemoveFormulaObjects;
begin
  frmGoPhast.PhastModel.FormulaManager.Remove(FThicknessFormula,
    GlobalRemoveModflowBoundaryItemSubscription,
    GlobalRestoreModflowBoundaryItemSubscription, self);
  frmGoPhast.PhastModel.FormulaManager.Remove(FHydraulicConductivityFormula,
    GlobalRemoveModflowBoundaryItemSubscription,
    GlobalRestoreModflowBoundaryItemSubscription, self);
end;

procedure THfbItem.SetBoundaryFormula(Index: integer; const Value: string);
begin
  case Index of
    ThicknessPosition:
      Thickness := Value;
    HydraulicConductivityPosition:
      HydraulicConductivity := Value;
    else Assert(False);
  end;
end;

procedure THfbItem.SetHydraulicConductivity(const Value: string);
begin
  UpdateFormula(Value, HydraulicConductivityPosition, FHydraulicConductivityFormula);
end;

procedure THfbItem.SetThickness(const Value: string);
begin
  UpdateFormula(Value, ThicknessPosition, FThicknessFormula);
end;

{ THfbRecord }

procedure THfbRecord.Cache(Comp: TCompressionStream; Strings: TStringList);
begin
  WriteCompCell(Comp, Cell1);
  WriteCompCell(Comp, Cell2);
  WriteCompReal(Comp, Thickness);
  WriteCompReal(Comp, HydraulicConductivity);
  WriteCompReal(Comp, StartingTime);
  WriteCompReal(Comp, EndingTime);
  WriteCompInt(Comp, Strings.IndexOf(ThicknessAnnotation));
  WriteCompInt(Comp, Strings.IndexOf(HydraulicConductivityAnnotation));
end;

procedure THfbRecord.RecordStrings(Strings: TStringList);
begin
  Strings.Add(ThicknessAnnotation);
  Strings.Add(HydraulicConductivityAnnotation);
end;

procedure THfbRecord.Restore(Decomp: TDecompressionStream;
  Annotations: TStringList);
begin
  Cell1 := ReadCompCell(Decomp);
  Cell1 := ReadCompCell(Decomp);
  Thickness := ReadCompReal(Decomp);
  HydraulicConductivity := ReadCompReal(Decomp);
  StartingTime := ReadCompReal(Decomp);
  EndingTime := ReadCompReal(Decomp);
  ThicknessAnnotation := Annotations[ReadCompInt(Decomp)];
  HydraulicConductivityAnnotation := Annotations[ReadCompInt(Decomp)];
end;

{ THfbStorage }

procedure THfbStorage.Clear;
begin
  SetLength(FHfbArray, 0);
  FCleared := True;
end;

function THfbStorage.GetHfbArray: THfbArray;
begin
  if FCached and FCleared then
  begin
    RestoreData;
  end;
  result := FHfbArray;
end;

procedure THfbStorage.Restore(DecompressionStream: TDecompressionStream;
  Annotations: TStringList);
var
  Index: Integer;
  Count: Integer;
begin
  DecompressionStream.Read(Count, SizeOf(Count));
  SetLength(FHfbArray, Count);
  for Index := 0 to Count - 1 do
  begin
    FHfbArray[Index].Restore(DecompressionStream, Annotations);
  end;
end;

procedure THfbStorage.Store(Compressor: TCompressionStream);
var
  Index: Integer;
  Count: Integer;
  Strings: TStringList;
begin
  Strings := TStringList.Create;
  try
    Strings.Sorted := true;
    Strings.Duplicates := dupIgnore;
    Count := Length(FHfbArray);
    for Index := 0 to Count - 1 do
    begin
      FHfbArray[Index].RecordStrings(Strings);
    end;
    WriteCompInt(Compressor, Strings.Count);

    for Index := 0 to Strings.Count - 1 do
    begin
      WriteCompString(Compressor, Strings[Index]);
    end;

    Compressor.Write(Count, SizeOf(Count));
    for Index := 0 to Count - 1 do
    begin
      FHfbArray[Index].Cache(Compressor, Strings);
    end;

  finally
    Strings.Free;
  end;
end;

{ THfbTimeListLink }

procedure THfbTimeListLink.CreateTimeLists;
begin
  inherited;

end;

destructor THfbTimeListLink.Destroy;
begin

  inherited;
end;

{ THfbCollection }

function THfbCollection.Add: THfbItem;
begin
  Result := inherited Add as THfbItem;
end;

procedure THfbCollection.AddSpecificBoundary(AModel: TBaseModel);
begin
  AddBoundary(THfbStorage.Create(AModel));
end;

function THfbCollection.AdjustedFormula(FormulaIndex,
  ItemIndex: integer): string;
begin

end;

procedure THfbCollection.AssignArrayCellValues(DataSets: TList;
  ItemIndex: Integer; AModel: TBaseModel);
begin
  inherited;

end;

procedure THfbCollection.AssignCellList(Expression: TExpression;
  ACellList: TObject; BoundaryStorage: TCustomBoundaryStorage;
  BoundaryFunctionIndex: integer; Variables, DataSets: TList;
  AModel: TBaseModel; AScreenObject: TObject);
var
  HfbStorage: THfbStorage;
  CellList: TCellAssignmentList;
  Index: Integer;
  ACell: TCellAssignment;
  LocalScreenObject: TScreenObject;
  ErrorAnnotation: string;
begin
  Assert(BoundaryFunctionIndex in [ThicknessPosition, HydraulicConductivityPosition]);
  Assert(Expression <> nil);

  HfbStorage := BoundaryStorage as THfbStorage;
  CellList := ACellList as TCellAssignmentList;
  for Index := 0 to CellList.Count - 1 do
  begin
    ACell := CellList[Index];
    UpdateCurrentScreenObject(AScreenObject as TScreenObject);
    UpdateRequiredListData(DataSets, Variables, ACell, AModel);
    // 2. update locations
    try
      Expression.Evaluate;
      with HfbStorage.HfbArray[Index] do
      begin
        case BoundaryFunctionIndex of
          ThicknessPosition:
            begin
              Thickness := Expression.DoubleResult;
              ThicknessAnnotation := ACell.Annotation;
            end;
          HydraulicConductivityPosition:
            begin
              HydraulicConductivity := Expression.DoubleResult;
              HydraulicConductivityAnnotation := ACell.Annotation;
            end;
          else
            Assert(False);
        end;
      end;
    except on E: EMathError do
      begin
        ErrorAnnotation := '';
        with HfbStorage.HfbArray[Index] do
        begin
          case BoundaryFunctionIndex of
            ThicknessPosition:
              begin
                Thickness := 0;
                ThicknessAnnotation := StrHFBThicknessSetTo;
                ErrorAnnotation := ThicknessAnnotation;
              end;
            HydraulicConductivityPosition:
              begin
                HydraulicConductivity := 0;
                HydraulicConductivityAnnotation := StrHFBHydraulicConduc;
                ErrorAnnotation := HydraulicConductivityAnnotation;
              end;
            else
              Assert(False);
          end;
        end;
        LocalScreenObject := ScreenObject as TScreenObject;

        frmErrorsAndWarnings.AddError(AModel, ErrorAnnotation,
          Format(StrObject0sLayerError,
          [LocalScreenObject.Name, ACell.Layer+1, ACell.Row+1,
          ACell.Column+1, E.Message]), LocalScreenObject);
      end;
    end;
  end;
end;

procedure THfbCollection.AssignListCellLocation(
  BoundaryStorage: TCustomBoundaryStorage; ACellList: TObject);
var
  HfbStorage: THfbStorage;
  CellList: TCellAssignmentList;
  Index: Integer;
  ACell: TCellAssignment;
begin
  HfbStorage := BoundaryStorage as THfbStorage;
  CellList := ACellList as TCellAssignmentList;
  for Index := 0 to CellList.Count - 1 do
  begin
    ACell := CellList[Index];
    if ACell.LgrEdge then
    begin
      Continue;
    end;
    with HfbStorage.HfbArray[Index] do
    begin
      Cell1.Layer := ACell.Layer;
      Cell1.Row := ACell.Row;
      Cell1.Column := ACell.Column;
      Cell1.Section := ACell.Section;
    end;
  end;
end;

function THfbCollection.GetItems(Index: Integer): THfbItem;
begin
  result := inherited Items[Index] as THfbItem;
end;

function THfbCollection.GetTimeListLinkClass: TTimeListsModelLinkClass;
begin
  result := THfbTimeListLink;
end;

procedure THfbCollection.InvalidateHydraulicConductivity(Sender: TObject);
begin

end;

procedure THfbCollection.InvalidateThickness(Sender: TObject);
begin

end;

class function THfbCollection.ItemClass: TBoundaryItemClass;
begin
  result := THfbItem;
end;

procedure THfbCollection.SetBoundaryStartAndEndTime(BoundaryCount: Integer;
  Item: TCustomModflowBoundaryItem; ItemIndex: Integer; AModel: TBaseModel);
begin
  SetLength((Boundaries[ItemIndex, AModel] as THfbStorage).FHfbArray, BoundaryCount);
  inherited;

end;

procedure THfbCollection.SetItems(Index: Integer; const Value: THfbItem);
begin
  inherited Items[Index] := value;
end;

initialization
  RegisterClass(THfbBoundary);

end.
