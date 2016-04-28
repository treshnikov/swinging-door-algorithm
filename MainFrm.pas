unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, DataCompressionU;

const
  X0_ = 10;
  Y0_ = 100;
  ErrorOffset = 12;

type

  TForm1 = class(TForm)
    Image1: TImage;
    mLog: TMemo;
    btnStep: TButton;
    btnClear: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
  private
    FCompressManager: TCompressManager;
    FBackUpBitmap: TBitmap;
    FLastCorridorStartPoint: TCompressDataPoint;

    procedure DoBackupBitmap;
    procedure LoadBackupBitmap;
    procedure DrawCorridor;
    procedure DrawPiVotPoints;
    procedure DrawPoint(const APoint: TCompressDataPoint; const AColor: TColor; const ASolid: Boolean);
    procedure DoLine(const x0, y0, x1, y1: Integer; const AColor: TColor);
    procedure DoPoint(const x, y: Integer; const ACollor: TColor; const ASolid: Boolean);
    procedure DoClear;
  public
    procedure RecivePoint(var AX: TDateTime; AY: Double; AStatus: Integer);
  end;

var
  Form1: TForm1;

implementation
var
  ClickNumber: Integer;

{$R *.dfm}

procedure TForm1.btnClearClick(Sender: TObject);
begin
  DoClear;
end;

procedure TForm1.btnStepClick(Sender: TObject);
var
  x: TDateTime;
  y: Double;
  s: Integer;
begin
  // генерирую точку
  X := 25 * ClickNumber;
  Y:= 70*Sin(ClickNumber);

  RecivePoint(x, y, s);
end;

procedure TForm1.DoBackupBitmap;
begin
  FBackUpBitmap.Assign(Image1.Picture.Bitmap);
end;

procedure TForm1.DoClear;
begin
  mLog.Clear;
  with Image1.Canvas do
  begin
    Brush.Color := clWhite;
    FillRect(Rect(0, 0, Width, Height));
    Pen.Color := clSilver;
  end;

  DoLine(X0_, Y0_, 10, 390, clSkyBlue);
  DoLine(X0_, Y0_, 750, Y0_, clSkyBlue);

  ClickNumber := 0;

  DoBackupBitmap;
  FreeAndNil(FCompressManager);
  FCompressManager := TCompressManager.Create(ErrorOffset, 30);
end;

procedure TForm1.DoLine(const x0, y0, x1, y1: Integer; const AColor: TColor);
begin
  with Image1.Canvas do
  begin
    Pen.Color := AColor;
    MoveTo(x0, Image1.Height - y0);
    LineTo(x1, Image1.Height - y1);
  end;
end;

procedure TForm1.DoPoint(const x, y: Integer; const ACollor: TColor; const ASolid: Boolean);
begin
  with Image1.Canvas do
  begin
    Pen.Color := ACollor;

    if ASolid then
    begin
      Brush.Color := ACollor;
      Brush.Style := bsSolid;
    end
    else
    begin
      Brush.Color := clWhite;
    end;

    Ellipse(X0_ + x - 3, -Y0_ + Image1.Height - y - 3, X0_ + x + 3, -Y0_ + Image1.Height - y + 3);
    Brush.Color := clWhite;
  end;
end;

procedure TForm1.DrawCorridor;
var
  i: Integer;
  x0, x, y: Double;
begin
  with Image1.Canvas do
  begin
    x0 := FCompressManager.CorridorStartPoint.X;
    for i := -1500 to 1500 do
    begin
      x := x0 + i;
      y := FCompressManager.SU * x;
      Pixels[X0_ + Trunc(x0 + x), - Y0_ + Image1.Height - Trunc(y + FCompressManager.PivotU.Y)] := clRed;
    end;

    for i := -1500 to 1500 do
    begin
      x := x0 + i;
      y := FCompressManager.SL * x;
      Pixels[X0_ + Trunc(x0 + x), - Y0_ + Image1.Height - Trunc(y + FCompressManager.PivotL.Y)] := clGreen;
    end;

  end;
end;

procedure TForm1.DrawPoint(const APoint: TCompressDataPoint; const AColor: TColor; const ASolid: Boolean);
begin
  DoPoint(Trunc(APoint.X), Trunc(APoint.Y), AColor, ASolid);
end;

procedure TForm1.DrawPiVotPoints;
begin
  DoPoint(Trunc(FCompressManager.PivotU.X), Trunc(FCompressManager.PivotU.Y), clRed, False);
  DoPoint(Trunc(FCompressManager.PivotL.X), Trunc(FCompressManager.PivotL.Y), clGreen, False);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FBackUpBitmap := TBitmap.Create;

  FCompressManager := TCompressManager.Create(ErrorOffset, 30);

  DoClear;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FBackUpBitmap);
  FreeAndNil(FCompressManager);
end;

procedure TForm1.Image1Click(Sender: TObject);
var
  x: TDateTime;
  y: Double;
  s: Integer;
begin
(*
  x := -10 + Mouse.CursorPos.X - Form1.Left;
  y := 25 +Y0_ +Y0_ -30 + - Mouse.CursorPos.Y + Form1.Top;

  RecivePoint(x, y, s);
*)  
end;

procedure TForm1.LoadBackupBitmap;
begin
  Image1.Picture.Assign(FBackUpBitmap);
end;

procedure TForm1.RecivePoint(var AX: TDateTime; AY: Double; AStatus: Integer);
begin
  LoadBackupBitmap;

  DoPoint(Trunc(AX), Trunc(AY), clBlue, False);
  Image1.Canvas.TextOut(X0_ + Trunc(AX) + 3, -Y0_ + Image1.Height - Trunc(AY), IntToStr(ClickNumber + 1));

  if FCompressManager.ReceivePoint(AX, AY, AStatus) then
  begin
    if (ClickNumber <> 0) then
    begin
      DoLine(X0_ + Trunc(FLastCorridorStartPoint.X), Y0_ + Trunc(FLastCorridorStartPoint.Y),
        X0_ + Trunc(AX), Y0_ + Trunc(AY), clPurple);
    end;

    DrawPoint(FCompressManager.CorridorStartPoint, clPurple, True);

    mLog.Lines.Add('Начало новго коридора [' +
      FormatFloat('0', FCompressManager.CorridorStartPoint.X) + ';' +
      FormatFloat('0', FCompressManager.CorridorStartPoint.Y) + ']');

    FLastCorridorStartPoint.Init(AX, AY, AStatus);
  end
  else
  begin
    mLog.Lines.Add('Точка [' +
      FormatFloat('0', FCompressManager.PreviewPoint.X) + ';' +
      FormatFloat('0', FCompressManager.PreviewPoint.Y) + ']' +
      ' входит в коридор, ее не сохраняем');
  end;

  DoBackupBitmap;
  DrawPiVotPoints;
  if (ClickNumber <> 0) then
  begin
    DrawCorridor;
  end;
  Inc(ClickNumber);
end;

end.
