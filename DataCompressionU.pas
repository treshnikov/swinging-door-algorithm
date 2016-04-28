{*
  Модуль компресии данных, реализован алгоритм SwingDoor

  Класс TCompressManager содержит логику обработки данных с использованием
  алгоритма сжатия
  Метод TCompressManager.ReceivePoint() обрабатывает входящее значение точки
  и определяет, нужно ли сохранять точку в БД
}
unit DataCompressionU;

interface

type

  {*
    Точка на координатной плоскости XY
  }
  TCompressDataPoint = record
    X: Double;
    Y: Double;
    Status: Integer;

    procedure Init(const AX, AY: Double; const AStatus: Integer);
  end;

  {*
    Возможные отношения коэффициентов наклона дверей коридора
  }
  TSlopesRelation = (srNone,
    srNewSUIsIsGreater, // наколн верхней двери увеличился
    srNewSLIsLess,      // наклон нижнией двери уменьшился
    srSUIsGreaterSL     // двери открылись
    );

  {*
    Возможный результат регистрации точки
  }
  TRecivePointResult = (
    rpNone,
    rpRetainCorridorStartPoint // необходимо сохранить точку начала коридора
    );

  {*
    Класс реализует логику выборки точек, которые необходимо сохранить в БД
  }
  TCompressManager = class(TObject)
  private
    FIsNeedInit: Boolean;
    FErrorOffset: Double; // погрешность
    FCorridorTimeSec: Int64; // максимальное время в сек, в течение которого должна быть сохранена хотябы одна точка
    FLastRetainDate:  TDateTime;  // временная метка последней записи данных
    FCurrentPoint: TCompressDataPoint; // текущая точка c прибора
    FPreviewPoint: TCompressDataPoint; // предыдущая точка c прибора
    FCorridorStartPoint: TCompressDataPoint; // текущая точка начала коридора
    FU, FL: TCompressDataPoint; // опорные точки
    FSU, FSL: Double; // угловые коэффициенты наклона дверей коридора

    procedure EstablishPivotPoints;
    procedure InitSlopes;
    function CalculateCurrentSlopes: TSlopesRelation;
    function IsCorridorTimeExpired: Boolean;
  public
    constructor Create(const AErrorOffset: Double; const ACorridorTimeSec: Int64);

    function ReceivePoint(var ATimeStamp: TDateTime;
      var AValue: Double; var AStatus: Integer): Boolean;

    property CorridorStartPoint: TCompressDataPoint read FCorridorStartPoint;
    property CurrentPoint: TCompressDataPoint read FCurrentPoint;
    property PreviewPoint: TCompressDataPoint read FPreviewPoint;
    property SU: Double read FSU;
    property SL: Double read FSL;
    property PivotU: TCompressDataPoint read FU;
    property PivotL: TCompressDataPoint read FL; 
  end;

implementation

uses
  DateUtils, SysUtils;

{ TCompressManager }

{*
  Расчет угловых коэффициентов коридора
}
function TCompressManager.CalculateCurrentSlopes: TSlopesRelation;
Var
  SU, SL: Double;
begin
  Result := srNone;
  SU := (FCurrentPoint.Y - FCorridorStartPoint.Y - FErrorOffset) /
    (FCurrentPoint.X - FCorridorStartPoint.X);

  SL := (FCurrentPoint.Y - FCorridorStartPoint.Y + FErrorOffset) /
    (FCurrentPoint.X - FCorridorStartPoint.X);

  if (SU > FSU) then
  begin
    FSU := SU;
    Result := srNewSUIsIsGreater;
  end;

  if (SL < FSL) then
  begin
    FSL := SL;
    Result := srNewSLIsLess;
  end;

  if (FSU > FSL) then
  begin
    Result := srSUIsGreaterSL;
  end;
end;

constructor TCompressManager.Create(const AErrorOffset: Double; const ACorridorTimeSec: Int64);
begin
  inherited Create;

  FIsNeedInit := True;
  FErrorOffset := AErrorOffset;
  FCorridorTimeSec := ACorridorTimeSec;
  FLastRetainDate := Now; 
  FSU := 0;
  FSL := 0;
end;

{*
  Расчет опорных точек
}
procedure TCompressManager.EstablishPivotPoints;
begin
  FU.Init(FCorridorStartPoint.X, FCorridorStartPoint.Y + FErrorOffset, 0);
  FL.Init(FCorridorStartPoint.X, FCorridorStartPoint.Y - FErrorOffset, 0);
end;

{*
  Инициализация угловых коэффициентов дверей коридора
}
procedure TCompressManager.InitSlopes;
begin
  FSU := (FCurrentPoint.Y - FCorridorStartPoint.Y - FErrorOffset) /
    (FCurrentPoint.X - FCorridorStartPoint.X);

  FSL := (FCurrentPoint.Y - FCorridorStartPoint.Y + FErrorOffset) /
    (FCurrentPoint.X - FCorridorStartPoint.X);
end;

{*
  Возвращает True если время последней записи превосходит FCorridorTimeSec
}
function TCompressManager.IsCorridorTimeExpired: Boolean;
begin
  Result := (SecondsBetween(Now, FLastRetainDate) > FCorridorTimeSec);

  // если время истекло, то обновляем последнюю временную метку сохранения
  if Result then
  begin
    FLastRetainDate := Now;
  end;
end;

{*
  Регистрация новой точки
}
function TCompressManager.ReceivePoint(var ATimeStamp: TDateTime;
  var AValue: Double; var AStatus: Integer): Boolean;
begin
  Result := False;

  FPreviewPoint := FCurrentPoint;
  FCurrentPoint.Init(ATimeStamp, AValue, AStatus);

  // первую точку устанавливаю как коридорную точку
  // рассчитываю опорные точки
  if FIsNeedInit then
  begin
    FCorridorStartPoint := FCurrentPoint;
    EstablishPivotPoints;
    FIsNeedInit := False;

    // текущая точка должна быть сохранена в БД
    FLastRetainDate := Now;
    Result := True;
  end
  else
  begin
    if (FPreviewPoint.X <> FCorridorStartPoint.X) and
      (FPreviewPoint.Y <> FCorridorStartPoint.Y)
    then
    begin

      // вычисляю коэффициенты наклона дверей коридора
      case CalculateCurrentSlopes of
        // полученная точка входит в коридор
        srNone:
          begin
            // точка входит в текущий коридор
            // сохранять ее надо только если давно не сохраняли
            Result := IsCorridorTimeExpired;
          end;

        // верхняя граница коридора изменилась
        srNewSUIsIsGreater:
          begin
            // сохранять надо точку только если давно не сохраняли
            Result := IsCorridorTimeExpired;
          end;

        // нижняя граница коридора изменилась
        srNewSLIsLess:
          begin
            // сохранять надо точку только если давно не сохраняли
            Result := IsCorridorTimeExpired;
          end;

        // двери открылись
        srSUIsGreaterSL:
          begin
            // текущая точка не входит в коридор
            // предыдущая точка открывает коридор происходит перерасчет коэффициентов
            FCorridorStartPoint := FPreviewPoint;
            EstablishPivotPoints;
            InitSlopes;
            FLastRetainDate := Now;

            // возвращаю данные предыдущей точки для сохранения
            ATimeStamp := FCorridorStartPoint.X;
            AValue := FCorridorStartPoint.Y;
            AStatus := FCorridorStartPoint.Status;

            Result := True;
          end;
      end; //case
    end
    else
    begin
      InitSlopes;
    end;
  end;
end;

{ TDataPoint }

procedure TCompressDataPoint.Init(const AX, AY: Double; const AStatus: Integer);
begin
  X := AX;
  Y := AY;
  Status := AStatus;
end;

end.
