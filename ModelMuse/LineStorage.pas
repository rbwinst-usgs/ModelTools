// This file contains classes for storing contour lines generated by
// @link(TRICP_Pascal).
//
// @author(Richard B. Winston <rbwinst@usgs.gov>)
// This file is in the public domain.

unit LineStorage;

interface

Uses System.Types, Classes, Contnrs, //TriCP_Routines,
  RealListUnit, QuadTreeClass, TriPackRoutines, GoPhastTypes,
  System.Generics.Collections;{, SysUtils,
  Dialogs;   }

Type
  // @name represents the location where a symbol should be plotted.
  TSymbolStorage = class(TObject)
    X: double;
    Y: double;

    function Equal(const Symb: TSymbolStorage): boolean;
  end;

  // @name stores a list of @link(TSymbolStorage).
  TSymbolList = class(TObjectList<TSymbolStorage>)
    // implemented as TObjectList
//    FSymbols: TList;
//  private
//    function GetCount: integer;
//    function GetItems(const Index: integer): TSymbolStorage;

  public
//    Constructor Create;
//    Destructor Destroy; override;
//    procedure Add(const X, Y: double);

//    property Count: integer read GetCount;

//    property Items[const Index: integer]: TSymbolStorage read GetItems; default;

//    Procedure Clear;
    function Equal(const SymbList: TSymbolList): boolean;
  end;

  // @name stores a number and the location where that number should be
  // plotted.
  TNumberStorage = class(TObject)
    X: double;
    Y: double;
    Number: double;

    function Equal(const Num: TNumberStorage): boolean;
  end;

  // @name stores a list of @link(TNumberStorage)s.
  TNumberList = class(TObjectList<TNumberStorage>)
    // implemented as TObjectList
//    FNumbers: TList;
//  private
//    function GetCount: integer;
//    function GetItems(const Index: integer): TNumberStorage;

  public
//    procedure Add(const X, Y, Number: double);
//    Procedure Clear;
//
//    property Count: integer read GetCount;
//
//    Constructor Create;
//    Destructor Destroy; override;
    function Equal(const NumList: TNumberList): boolean;

//    property Items[const Index: integer]: TNumberStorage read GetItems; default;

  end;


  // @name represents one location on a @link(TLine).
  TLocation = class(TObject)
    X: double;
    Y: double;
    function Equal(const Loc: TLocation): boolean;
  end;

  TLineList = class;

  // @name represents one contour line.
  TLine = class(TObject)
  private
    // implemented as TObjectList
    FLocations: TObjectList<TLocation>;
    FMaxX: double;
    FMinX: double;
    FMaxY: double;
    FMinY: double;
    FContourLevel: double;
    FTriangleNumber: longint;
    FLineList: TLineList;
    function GetCount: integer;
    function GetItems(const Index: integer): TLocation;
  public
    Constructor Create;
    Destructor Destroy; override;
    procedure Add(Const X, Y: double);
    property Count: integer read GetCount;
    // @name tests whether two @classname are nearly the same.
    Function Equal(const Line: TLine): boolean;
    property Items[const Index: integer]: TLocation read GetItems; default;
    Property MaxX: double read FMaxX;
    Property MinX: double read FMinX;
    Property MaxY: double read FMaxY;
    Property MinY: double read FMinY;
    // @name represents the value of the this contour line.
    property ContourLevel: double read FContourLevel write FContourLevel;
    // @name represents the triangle that was used to generate this
    // @classname.  In @link(TLineList) a @name of 1 would represent the
    // points identified by @link(TLineList.Triangles)[0], [1], and [2].
    // In general the points in @link(TLineList.Triangles) would be
    // [(TriangleNumber-1)*3], [(TriangleNumber-1)*3+1],
    // and [(TriangleNumber-1)*3+2].
    // @name is no longer meaningful after @link(TLineList.MergeLines)
    // has been called.
    property TriangleNumber: longint read FTriangleNumber write FTriangleNumber;
  end;

  // @name stores a series of @link(TLine)s for a set of points.
  TLineList = class(TObject)
  private
    // implemented as TObjectList
    FLines: TObjectList<TLine>;
    FNumbers: TNumberList;
    FSymbols: TSymbolList;
    FTriangles: TIntArray;
    FXD: TRealArray;
    FYD: TRealArray;
    procedure JoinLineEndToClosestEnd(const ClosestEnd: TLine;
      const LineEndPoint: TLocation; const Line: TLine;
      var MergedLines: Boolean; const QuadTree: TRbwQuadTree);
    procedure JoinLineEndToClosestStart(const ClosestStart: TLine;
      const LineEndPoint: TLocation; const Line: TLine;
      var MergedLines: Boolean; const QuadTree: TRbwQuadTree);
    procedure JoinLineStartToClosestEnd(const ClosestEnd: TLine;
      const LineStartPoint: TLocation; const Line: TLine;
      var MergedLines: Boolean; const QuadTree: TRbwQuadTree);
    procedure JoinLineStartToClosestStart(const ClosestStart: TLine;
      const LineStartPoint: TLocation; const Line: TLine;
      var MergedLines: Boolean; const QuadTree: TRbwQuadTree);
    procedure FillQuadTreeList(QuadTrees: TList; ContourLevels: TRealList);
    function GetCount: integer;
    function GetItems(const Index: integer): TLine;
    function GetMaxX: double;
    function GetMaxY: double;
    function GetMinX: double;
    function GetMinY: double;
    procedure RemoveDuplicates(var ContourLevels: TRealList);
    procedure SetTriangles(const Value: TIntArray);
    procedure SetXD(const Value: TRealArray);
    procedure SetYD(const Value: TRealArray);
  public
    // @name stores a list of numbers to be plotted along with the locations
    // where they should be plotted.
    property Numbers: TNumberList read FNumbers;
    // @name stores the locations where a symbol should be plotted.
    property Symbols: TSymbolList read FSymbols;
    // @name represents the X-coordinates of the triangles used to determine
    // the contour lines.
    property XD: TRealArray read FXD write SetXD;
    // @name represents the Y-coordinates of the triangles used to determine
    // the contour lines.
    property YD: TRealArray read FYD write SetYD;
    {
    Integer array. the dimension is 3*the number of triangles.
    Point numbers for the triangles.
    The first 3 numbers determine the vertices of the
    first triangle, the next 3 for the second and so on.
    The numbers Correspond to the indices of the
    XD and YD arrays PLUS 1. they are arranged counter-
    clockwise within a triangle.

    For instance if the first three values in @name were
    2, 4,  and 6, the triangle vertices would be at
    (XD[1], YD[1]), (XD[3], YD[3]), and (XD[5], YD[5]).
    }
    property Triangles: TIntArray read FTriangles write SetTriangles;
    Constructor Create;
    Destructor Destroy; override;
    procedure Add(Line: TLine);
    property Count: integer read GetCount;
    property Items[const Index: integer]: TLine read GetItems; default;
    Procedure Clear;
    Property MaxX: Double read GetMaxX;
    Property MinX: Double read GetMinX;
    Property MaxY: Double read GetMaxY;
    Property MinY: Double read GetMinY;
    // @name is used to test whether two @classname are the same or nearly the
    // same as each other.
    Function Equal(const LineList: TLineList): boolean;
    // @name merges lines that have the same contour value if the ends of the
    // lines are at the same or nearly the same location.
    // @link(TLine.TriangleNumber) is no longer valid after @name is called.
    procedure MergeLines;
  end;

  // @name stores a series of @link(TLineList)s. 
  TPlotList = TObjectList<TLineList>;
    // implemented as TObjectList
//    FPlots: TObjectList<TLineList>;
//  private
//    function GetCount: integer;
//    function GetItems(const Index: integer): TLineList;
//  public
//    Constructor Create;
//    Destructor Destroy; override;
//    procedure Add(LineList: TLineList);
//    property Count: integer read GetCount;
//    property Items[const Index: integer]: TLineList read GetItems; default;
//    Procedure Clear;
//  end;


var
  // @name is the @link(TLine) that is currently having values added to it.
  CurrentLine: TLine = nil;
  // @name is the current contour plot (@link(TLineList)) that is currently
  // being editted.
  CurrentLineList: TLineList = nil;
//  @name stores a series of contour plots. 
  PlotList: TPlotList;


implementation

uses
  Math, FastGEO;
var
  Epsilon: double = 0.000025;
  LocationEpsilon: double;

function NearlyTheSame(const A, B: double): boolean;
begin
  result := (A = B);

  if not result then
  begin
    result := Abs(A-B) < Epsilon;

//    if not result then
//    begin
//      if A <> -B then
//      begin
//        result := Abs(A-B)/(A+B) < Epsilon;
//      end;
//    end;
  end;
end;

function Distance(const A, B: TLocation): double;
begin
  result := Sqrt(Sqr(A.X-B.X) + Sqr(A.Y-B.Y));
end;

function CompareLineLengths(Line1, Line2: Pointer): Integer;
begin
  result := TLine(Line1).Count - TLine(Line2).Count;
end;

{ TLine }

procedure TLine.Add(const X, Y: double);
var
  Location: TLocation;
begin
  Location := TLocation.Create;
  Location.X := X;
  Location.Y := Y;
  FLocations.Add(Location);
  if FLocations.Count = 1 then
  begin
    FMaxX := X;
    FMinX := X;
    FMaxY := Y;
    FMinY := Y;
  end
  else
  begin
    if X > FMaxX then
    begin
      FMaxX := X;
    end;
    if X < FMinX then
    begin
      FMinX := X;
    end;
    if Y > FMaxY then
    begin
      FMaxY := Y;
    end;
    if Y < FMinY then
    begin
      FMinY := Y;
    end;
  end;
end;

constructor TLine.Create;
begin
  FLocations := TObjectList<TLocation>.Create;
  FLineList := nil;
end;

destructor TLine.Destroy;
begin
  FLocations.Free;
  inherited;
end;

function TLine.Equal(const Line: TLine): boolean;
var
  Index: integer;
begin
  result := Count = Line.Count;
  if result then
  begin
    for Index := 0 to Count -1 do
    begin
      result := Items[Index].Equal(Line[Index]);
      if not result then
      begin
        break;
      end;
    end;
    if result then
    begin
      Exit;
    end;
    // check for identical locations in reverse order.
    for Index := 0 to Count -1 do
    begin
      result := Items[Index].Equal(Line[Count -1 - Index]);
      if not result then
      begin
        Exit;
      end;
    end;
  end;
end;

function TLine.GetCount: integer;
begin
  result := FLocations.Count;
end;

function TLine.GetItems(const Index: integer): TLocation;
begin
  result := FLocations[Index] as TLocation;
end;

{ TLineList }

procedure TLineList.Add(Line: TLine);
begin
  FLines.Add(Line);
  Line.FLineList := self;
end;

procedure TLineList.Clear;
begin
  FLines.Clear;
  FNumbers.Clear;
  FSymbols.Clear;
end;

constructor TLineList.Create;
begin
  FLines := TObjectList<TLine>.Create;
  FNumbers := TNumberList.Create;
  FSymbols:= TSymbolList.Create;
end;

destructor TLineList.Destroy;
begin
  FLines.Free;
  FNumbers.Free;
  FSymbols.Free;
  inherited;
end;

function TLineList.Equal(const LineList: TLineList): boolean;
var
  Index: integer;
begin
  result := (Count = LineList.Count) and FNumbers.Equal(LineList.FNumbers)
    and FSymbols.Equal(LineList.FSymbols);
  if result then
  begin
    for Index := 0 to Count -1 do
    begin
      result := Items[Index].Equal(LineList[Index]);
      if not result then
      begin
        Exit;
      end;
    end;
  end;

end;

function TLineList.GetCount: integer;
begin
  result := FLines.Count;
end;

function TLineList.GetItems(const Index: integer): TLine;
begin
  result := FLines[Index] as TLine;
end;

function TLineList.GetMaxX: double;
var
  Index: integer;
begin
  result := 0;
  for Index := 0 to Count -1 do
  begin
    if (Index = 0) or (result < Items[Index].MaxX) then
    begin
      result := Items[Index].MaxX;
    end;
  end;
end;

function TLineList.GetMaxY: double;
var
  Index: integer;
begin
  result := 0;
  for Index := 0 to Count -1 do
  begin
    if (Index = 0) or (result < Items[Index].MaxY) then
    begin
      result := Items[Index].MaxY;
    end;
  end;
end;

function TLineList.GetMinX: double;
var
  Index: integer;
begin
  result := 0;
  for Index := 0 to Count -1 do
  begin
    if (Index = 0) or (result > Items[Index].MinX) then
    begin
      result := Items[Index].MinX;
    end;
  end;
end;

function TLineList.GetMinY: double;
var
  Index: integer;
begin
  result := 0;
  for Index := 0 to Count -1 do
  begin
    if (Index = 0) or (result > Items[Index].MinY) then
    begin
      result := Items[Index].MinY;
    end;
  end;
end;

procedure TLineList.MergeLines;
var
  ContourLevels: TRealList;
  QuadTrees: TList;
  QuadTree: TRbwQuadTree;
  MergedLines: Boolean;
  LineIndex: Integer;
  Line: TLine;
  LineStartPoint: TLocation;
  LineEndPoint: TLocation;
  X1: double;
  Y1: double;
  X2: double;
  Y2: double;
  NeighborList: TList;
  Points: TQuadPointArray;
  QuadIndex: Integer;
  QuadPoint: TQuadPoint;
  Index: Integer;
  MatchLine: TLine;
  MatchLineStartPoint: TLocation;
  MatchLineEndPoint: TLocation;
  MergedTwoLines: Boolean;
  StoredEpsilon: double;
begin
  ContourLevels := TRealList.Create;
  QuadTrees := TObjectList.Create;
  try

    FillQuadTreeList(QuadTrees, ContourLevels);
    StoredEpsilon := Epsilon;
    Epsilon := LocationEpsilon;

    MergedLines := True;
    while MergedLines do
    begin
      MergedLines := False;
      for LineIndex := Count - 1 downto 0 do
      begin
        Line := Items[LineIndex];

        LineStartPoint := Line.Items[0];
        LineEndPoint := Line.Items[Line.Count -1];
        if LineStartPoint.Equal(LineEndPoint) then
        begin
          Continue;
        end;
        X1 := LineStartPoint.X;
        Y1 := LineStartPoint.Y;
        X2 := LineEndPoint.X;
        Y2 := LineEndPoint.Y;

        QuadTree := QuadTrees[ContourLevels.IndexOf(Line.ContourLevel)];

        NeighborList := TList.Create;
        try

          QuadTree.FindNearestPoints(LineStartPoint.X,
            LineStartPoint.Y, 2, Points);
          if Length(Points) > 0 then
          begin
            for QuadIndex := 0 to Length(Points) - 1 do
            begin
              QuadPoint := Points[QuadIndex];
              for Index := 0 to Length(QuadPoint.Data) - 1 do
              begin
                MatchLine := QuadPoint.Data[Index];
                if (MatchLine <> Line) and
                  (NeighborList.IndexOf(MatchLine) < 0) then
                begin
                  NeighborList.Add(MatchLine);
                end;
              end;
            end;
            for Index := 0 to NeighborList.Count -1 do
            begin
              MatchLine := NeighborList[Index];
              MatchLineStartPoint := MatchLine.Items[0];
              MatchLineEndPoint := MatchLine.Items[MatchLine.Count-1];
              MergedTwoLines := False;
              if MatchLineStartPoint.Equal(MatchLineEndPoint) then
              begin
                Continue;
              end;

              if Distance(LineStartPoint, MatchLineStartPoint) <
                Distance(LineStartPoint, MatchLineEndPoint) then
              begin
                JoinLineStartToClosestStart(MatchLine, LineStartPoint,
                  Line, MergedTwoLines, QuadTree);
              end
              else
              begin
                JoinLineStartToClosestEnd(MatchLine, LineStartPoint, Line,
                  MergedTwoLines, QuadTree);
              end;
              if MergedTwoLines then
              begin
                FLines[LineIndex] := nil;
                Assert(QuadTree.RemovePoint(X1, Y1, Line));
                Assert(QuadTree.RemovePoint(X2, Y2, Line));
                MergedLines := True;
                break;
              end;
            end;
          end;
        finally
          NeighborList.Free;
        end;
      end;

      if MergedLines then
      begin
        FLines.Pack;
      end;

      for LineIndex := Count - 1 downto 0 do
      begin
        Line := Items[LineIndex];

        LineStartPoint := Line.Items[0];
        LineEndPoint := Line.Items[Line.Count -1];
        if LineStartPoint.Equal(LineEndPoint) then
        begin
          Continue;
        end;
        X1 := LineStartPoint.X;
        Y1 := LineStartPoint.Y;
        X2 := LineEndPoint.X;
        Y2 := LineEndPoint.Y;

        QuadTree := QuadTrees[ContourLevels.IndexOf(Line.ContourLevel)];

        NeighborList := TList.Create;
        try

          QuadTree.FindNearestPoints(LineEndPoint.X, LineEndPoint.Y, 2, Points);
          for QuadIndex := 0 to Length(Points) - 1 do
          begin
            QuadPoint := Points[QuadIndex];
            for Index := 0 to Length(QuadPoint.Data) - 1 do
            begin
              MatchLine := QuadPoint.Data[Index];
              if (MatchLine <> Line) and
                (NeighborList.IndexOf(MatchLine) < 0) then
              begin
                NeighborList.Add(MatchLine);
              end;
            end;
          end;
          for Index := 0 to NeighborList.Count -1 do
          begin
            MatchLine := NeighborList[Index];
            MatchLineStartPoint := MatchLine.Items[0];
            MatchLineEndPoint := MatchLine.Items[MatchLine.Count-1];
            MergedTwoLines := False;
            if MatchLineStartPoint.Equal(MatchLineEndPoint) then
            begin
              Continue;
            end;
            if Distance(LineEndPoint, MatchLineStartPoint) <
              Distance(LineEndPoint, MatchLineEndPoint) then
            begin
              JoinLineEndToClosestStart(MatchLine, LineEndPoint,
                Line, MergedTwoLines, QuadTree);
            end
            else
            begin
              JoinLineEndToClosestEnd(MatchLine, LineEndPoint, Line,
                MergedTwoLines, QuadTree);
            end;
            if MergedTwoLines then
            begin
              FLines[LineIndex] := nil;
              Assert(QuadTree.RemovePoint(X1, Y1, Line));
              Assert(QuadTree.RemovePoint(X2, Y2, Line));
              MergedLines := True;
              break;
            end;
          end;
        finally
          NeighborList.Free;
        end;
      end;
      if MergedLines then
      begin
        FLines.Pack;
      end;
    end;
  finally
    ContourLevels.Free;
    QuadTrees.Free;
    Epsilon := StoredEpsilon;
  end;
end;

procedure TLineList.RemoveDuplicates(var ContourLevels: TRealList);
var
  Line2: TLine;
  InnerLineIndex: Integer;
  Line1: TLine;
  LineIndex: Integer;
  DupList: TList;
  ContourIndex: Integer;
  Line: TLine;
  Index: Integer;
  Duplicates: TList;
  MinSegLength: double;
  PointIndex: Integer;
  Point1: TLocation;
  Point2: TLocation;
  TestDistance: double;
  StoredEpsilon: double;
begin
  ContourLevels.Clear;
  ContourLevels.Sorted := True;
  Duplicates := TObjectList.Create;
  MinSegLength := 0;
  try
    for Index := Count - 1 downto 0 do
    begin
      Line := Items[Index];
      if Line.Count = 1 then
      begin
        FLines.Delete(Index);
      end
      else
      begin
        ContourIndex := ContourLevels.IndexOf(Line.ContourLevel);
        if ContourIndex < 0 then
        begin
          ContourIndex := ContourLevels.Add(Line.ContourLevel);
          DupList := TList.Create;
          Duplicates.Insert(ContourIndex, DupList);
        end;
        DupList := Duplicates[ContourIndex];
        DupList.Add(Line);

        for PointIndex := 0 to Line.Count - 2 do
        begin
          Point1 := Line[PointIndex];
          Point2 := Line[PointIndex+1];
          TestDistance := Abs(Point1.X - Point2.X);
          if MinSegLength = 0 then
          begin
            MinSegLength := TestDistance;
          end
          else if TestDistance < MinSegLength then
          begin
            MinSegLength := TestDistance;
          end;
          TestDistance := Abs(Point1.Y - Point2.Y);
          if MinSegLength = 0 then
          begin
            MinSegLength := TestDistance;
          end
          else if TestDistance < MinSegLength then
          begin
            MinSegLength := TestDistance;
          end;
        end;
      end;
    end;
    StoredEpsilon := Epsilon;
    Epsilon := MinSegLength/10;
    LocationEpsilon := Epsilon;
    for Index := 0 to Duplicates.Count - 1 do
    begin
      DupList := Duplicates[Index];
      DupList.Sort(CompareLineLengths);
      for LineIndex := DupList.Count - 2 downto 0 do
      begin
        Line1 := DupList[LineIndex];
        for InnerLineIndex := DupList.Count - 1 downto LineIndex + 1 do
        begin
          Line2 := DupList[InnerLineIndex];
          if Line2.Count <> Line1.Count then
          begin
            Break;
          end;
          if Line1.Equal(Line2) then
          begin
            DupList.Delete(InnerLineIndex);
            FLines.Remove(Line2);
          end;
        end;
      end;
    end;
    Epsilon := StoredEpsilon;
  finally
    Duplicates.Free;
  end;
end;

procedure TLineList.SetTriangles(const Value: TIntArray);
begin
  FTriangles := Value;
  SetLength(FTriangles, Length(FTriangles));
end;

procedure TLineList.SetXD(const Value: TRealArray);
begin
  FXD := Value;
  SetLength(FXD, Length(FXD));
end;

procedure TLineList.SetYD(const Value: TRealArray);
begin
  FYD := Value;
  SetLength(FYD, Length(FYD));
end;

procedure TLineList.JoinLineStartToClosestEnd(const ClosestEnd: TLine;
  const LineStartPoint: TLocation; const Line: TLine;
  var MergedLines: Boolean; const QuadTree: TRbwQuadTree);
var
  LocationIndex: Integer;
  MatchLineEndPoint: TLocation;
  End1: Integer;
  End2: Integer;
  Index1: Integer;
  Location1: TLocation;
  Location2: TLocation;
  Index2: Integer;
  Location3: TLocation;
  Location4: TLocation;
begin
  // test if should be joined. If so,
  // join the starting point of Line to the ending point of ClosestEnd.
  if LineStartPoint.Equal(ClosestEnd.Items[ClosestEnd.Count - 1]) then
  begin
    End1 := Min(10, ClosestEnd.Count);
    End2 := Min(10, Line.Count);
    for Index1 := 0 to End1 - 2 do
    begin
      Location1 := ClosestEnd.Items[ClosestEnd.Count-1-Index1];
      Location2 := ClosestEnd.Items[ClosestEnd.Count-1-(Index1+1)];
      for Index2 := 0 to End2 - 2 do
      begin
        if (Index1=0) and (Index2 = 0) then
        begin
          Continue;
        end;
        Location3 := Line.Items[Index2];
        Location4 := Line.Items[(Index2+1)];
        if Intersect(
          Location1.X, Location1.Y,
          Location2.X, Location2.Y,
          Location3.X, Location3.Y,
          Location4.X, Location4.Y
          ) then
        begin
          Exit;
        end;
      end;
    end;

    MergedLines := True;
    MatchLineEndPoint := ClosestEnd.Items[ClosestEnd.Count-1];
    for LocationIndex := 1 to Line.Count - 1 do
    begin
      ClosestEnd.FLocations.Add(Line.FLocations[LocationIndex]);
    end;
    Line.FLocations.Delete(0);
    Line.FLocations.OwnsObjects := False;

    Assert(QuadTree.RemovePoint(MatchLineEndPoint.X,
      MatchLineEndPoint.Y, ClosestEnd));
    MatchLineEndPoint := ClosestEnd.Items[ClosestEnd.Count-1];
    QuadTree.AddPoint(MatchLineEndPoint.X,
      MatchLineEndPoint.Y, ClosestEnd);
  end;
end;

procedure TLineList.JoinLineEndToClosestEnd(const ClosestEnd: TLine;
  const LineEndPoint: TLocation; const Line: TLine; var MergedLines: Boolean;
  const QuadTree: TRbwQuadTree);
var
  LocationIndex: Integer;
  MatchLineEndPoint: TLocation;
  End1: Integer;
  End2: Integer;
  Index1: Integer;
  Location1: TLocation;
  Location2: TLocation;
  Index2: Integer;
  Location3: TLocation;
  Location4: TLocation;
begin
  // test if should be joined. If so,
  // join the ending point of Line to the ending point of ClosestEnd.
  if LineEndPoint.Equal(ClosestEnd.Items[ClosestEnd.Count - 1]) then
  begin
    End1 := Min(10, ClosestEnd.Count);
    End2 := Min(10, Line.Count);
    for Index1 := 0 to End1 - 2 do
    begin
      Location1 := ClosestEnd.Items[ClosestEnd.Count-1-Index1];
      Location2 := ClosestEnd.Items[ClosestEnd.Count-1-(Index1+1)];
      for Index2 := 0 to End2 - 2 do
      begin
        if (Index1=0) and (Index2 = 0) then
        begin
          Continue;
        end;
        Location3 := Line.Items[Line.Count-1-Index2];
        Location4 := Line.Items[Line.Count-1-(Index2+1)];
        if Intersect(
          Location1.X, Location1.Y,
          Location2.X, Location2.Y,
          Location3.X, Location3.Y,
          Location4.X, Location4.Y
          ) then
        begin
          Exit;
        end;
      end;
    end;

    MergedLines := True;
    MatchLineEndPoint := ClosestEnd.Items[ClosestEnd.Count-1];
    for LocationIndex := Line.Count - 2 downto 0 do
    begin
      ClosestEnd.FLocations.Add(Line.FLocations[LocationIndex]);
    end;
    Line.FLocations.Delete(Line.Count-1);
    Line.FLocations.OwnsObjects := False;
    Assert(QuadTree.RemovePoint(MatchLineEndPoint.X,
      MatchLineEndPoint.Y, ClosestEnd));
    MatchLineEndPoint := ClosestEnd.Items[ClosestEnd.Count-1];
    QuadTree.AddPoint(MatchLineEndPoint.X,
      MatchLineEndPoint.Y, ClosestEnd);
  end;
end;

procedure TLineList.JoinLineStartToClosestStart(const ClosestStart: TLine;
  const LineStartPoint: TLocation; const Line: TLine; var MergedLines: Boolean;
  const QuadTree: TRbwQuadTree);
var
  LocationIndex: Integer;
  MatchLineStartPoint: TLocation;
  End1: Integer;
  End2: Integer;
  Index1: Integer;
  Index2: Integer;
  Location1: TLocation;
  Location2: TLocation;
  Location3: TLocation;
  Location4: TLocation;
begin
//  // test if should be joined. If so,
//  // join the end of Line to the start of ClosestStart.
  if LineStartPoint.Equal(ClosestStart.Items[0]) then
  begin
    End1 := Min(10, ClosestStart.Count);
    End2 := Min(10, Line.Count);
    for Index1 := 0 to End1 - 2 do
    begin
      Location1 := ClosestStart.Items[Index1];
      Location2 := ClosestStart.Items[Index1+1];
      for Index2 := 0 to End2 - 2 do
      begin
        if (Index1=0) and (Index2 = 0) then
        begin
          Continue;
        end;
        Location3 := Line.Items[Index2];
        Location4 := Line.Items[Index2+1];
        if Intersect(
          Location1.X, Location1.Y,
          Location2.X, Location2.Y,
          Location3.X, Location3.Y,
          Location4.X, Location4.Y
          ) then
        begin
          Exit;
        end;
      end;
    end;
    MergedLines := True;
    MatchLineStartPoint := ClosestStart.Items[0];
    for LocationIndex :=  1 to Line.Count - 1 do
    begin
      ClosestStart.FLocations.Insert(0, Line.FLocations[LocationIndex]);
    end;
    Line.FLocations.Delete(0);
    Line.FLocations.OwnsObjects := False;

    Assert(QuadTree.RemovePoint(MatchLineStartPoint.X,
      MatchLineStartPoint.Y, ClosestStart));
    MatchLineStartPoint := ClosestStart.Items[0];
    QuadTree.AddPoint(MatchLineStartPoint.X,
      MatchLineStartPoint.Y, ClosestStart);
  end;
end;

procedure TLineList.JoinLineEndToClosestStart(const ClosestStart: TLine;
  const LineEndPoint: TLocation; const Line: TLine; var MergedLines: Boolean;
  const QuadTree: TRbwQuadTree);
var
  LocationIndex: Integer;
  MatchLineStartPoint: TLocation;
  End1: Integer;
  End2: Integer;
  Index1: Integer;
  Location1: TLocation;
  Location2: TLocation;
  Index2: Integer;
  Location3: TLocation;
  Location4: TLocation;
begin
  // test if should be joined. If so,
  // join the endpoint of Line to the starting point of ClosestStart.
  if LineEndPoint.Equal(ClosestStart.Items[0]) then
  begin
    End1 := Min(10, ClosestStart.Count);
    End2 := Min(10, Line.Count);
    for Index1 := 0 to End1 - 2 do
    begin
      Location1 := ClosestStart.Items[Index1];
      Location2 := ClosestStart.Items[(Index1+1)];
      for Index2 := 0 to End2 - 2 do
      begin
        if (Index1=0) and (Index2 = 0) then
        begin
          Continue;
        end;
        Location3 := Line.Items[Line.Count-1-Index2];
        Location4 := Line.Items[Line.Count-1-(Index2+1)];
        if Intersect(
          Location1.X, Location1.Y,
          Location2.X, Location2.Y,
          Location3.X, Location3.Y,
          Location4.X, Location4.Y
          ) then
        begin
          Exit;
        end;
      end;
    end;
    MergedLines := True;
    MatchLineStartPoint := ClosestStart.Items[0];
    for LocationIndex := Line.Count - 2 downto 0 do
    begin
      ClosestStart.FLocations.Insert(0, Line.FLocations[LocationIndex]);
    end;
    Line.FLocations.Delete(Line.Count-1);
    Line.FLocations.OwnsObjects := False;
    Assert(QuadTree.RemovePoint(MatchLineStartPoint.X,
      MatchLineStartPoint.Y, ClosestStart));
    MatchLineStartPoint := ClosestStart.Items[0];
    QuadTree.AddPoint(MatchLineStartPoint.X,
      MatchLineStartPoint.Y, ClosestStart);
  end;
end;


procedure TLineList.FillQuadTreeList(
  QuadTrees: TList; ContourLevels: TRealList);
var
  QuadTree: TRbwQuadTree;
  ContourIndex: Integer;
  Line: TLine;
  Index: Integer;
  Point: TLocation;
begin
  RemoveDuplicates(ContourLevels);

  ContourLevels.Clear;
  ContourLevels.Sorted := True;
  for Index := 0 to Count - 1 do
  begin
    Line := Items[Index];
    ContourIndex := ContourLevels.IndexOf(Line.ContourLevel);
    if ContourIndex < 0 then
    begin
      ContourIndex := ContourLevels.Add(Line.ContourLevel);
      QuadTree := TRbwQuadTree.Create(nil);
      QuadTrees.Insert(ContourIndex, QuadTree);
      QuadTree.XMax := MaxX;
      QuadTree.XMin := MinX;
      QuadTree.YMax := MaxY;
      QuadTree.YMin := MinY;
    end;
    QuadTree := QuadTrees[ContourIndex];
    Point := Line.Items[0];
    QuadTree.AddPoint(Point.X, Point.Y, Line);
    Point := Line.Items[Line.Count-1];
    QuadTree.AddPoint(Point.X, Point.Y, Line);
  end;
end;

{ TPlotList }

//procedure TPlotList.Add(LineList: TLineList);
//begin
//  FPlots.Add(LineList);
//end;
//
//procedure TPlotList.Clear;
//begin
//  FPlots.Clear;
//end;
//
//constructor TPlotList.Create;
//begin
//  FPlots := TObjectList.Create;
//end;
//
//destructor TPlotList.Destroy;
//begin
//  FPlots.Free;
//  inherited;
//end;
//
//function TPlotList.GetCount: integer;
//begin
//  result := FPlots.Count;
//end;
//
//function TPlotList.GetItems(const Index: integer): TLineList;
//begin
//  result := FPlots[Index];
//end;

{ TLocation }

function TLocation.Equal(const Loc: TLocation): boolean;
begin
  result := NearlyTheSame(X, Loc.X) and NearlyTheSame(Y, Loc.Y);
end;

function TNumberStorage.Equal(const Num: TNumberStorage): boolean;
begin
  result := NearlyTheSame(X,Num.X) and NearlyTheSame(Y,Num.Y)
    and (Number = Num.Number);
end;

//procedure TNumberList.Add(const X, Y, Number: Double);
//var
//  NumberStorage: TNumberStorage;
//begin
//  NumberStorage := TNumberStorage.Create;
//  NumberStorage.X := X;
//  NumberStorage.Y := Y;
//  NumberStorage.Number := Number;
//  FNumbers.Add(NumberStorage);
//end;
//
//procedure TNumberList.Clear;
//begin
//  FNumbers.Clear;
//end;
//
//constructor TNumberList.Create;
//begin
//  FNumbers := TObjectList.Create;
//end;
//
//destructor TNumberList.Destroy;
//begin
//  FNumbers.Free;
//  inherited;
//end;

function TNumberList.Equal(const NumList: TNumberList): boolean;
var
  Index: integer;
begin
  result := Count = NumList.Count;
  if result then
  begin
    for Index := 0 to Count -1 do
    begin
      result := Items[Index].Equal(NumList[Index]);
      if not result then
      begin
        Exit;
      end;
    end;
  end;
end;

//function TNumberList.GetCount: integer;
//begin
//  result := FNumbers.Count;
//end;
//
//function TNumberList.GetItems(const Index: integer): TNumberStorage;
//begin
//  result := FNumbers[Index];
//end;

function TSymbolStorage.Equal(const Symb: TSymbolStorage): boolean;
begin
  result := (X = Symb.X) and (Y = Symb.Y);
end;

//procedure TSymbolList.Add(const X, Y: double);
//var
//  SymbolStorage: TSymbolStorage;
//begin
//  SymbolStorage:= TSymbolStorage.Create;
//  SymbolStorage.X := X;
//  SymbolStorage.Y := Y;
//  FSymbols.Add(SymbolStorage);
//end;
//
//procedure TSymbolList.Clear;
//begin
//  FSymbols.Clear;
//end;

//constructor TSymbolList.Create;
//begin
//  FSymbols := TObjectList.Create;
//end;
//
//destructor TSymbolList.Destroy;
//begin
//  FSymbols.Free;
//  inherited;
//end;

function TSymbolList.Equal(const SymbList: TSymbolList): boolean;
var
  Index: integer;
begin
  result := Count = SymbList.Count;
  if result then
  begin
    for Index := 0 to Count -1 do
    begin
      result := Items[Index].Equal(SymbList[Index]);
      if not result then
      begin
        Exit;
      end;
    end;
  end;
end;

//function TSymbolList.GetCount: integer;
//begin
//  result := FSymbols.Count;
//end;
//
//function TSymbolList.GetItems(const Index: integer): TSymbolStorage;
//begin
//  result := FSymbols[Index];
//end;

initialization
//  PlotList := TPlotList.Create;

finalization
//  PlotList.Free;

end.