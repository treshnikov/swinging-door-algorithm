program SwingDoorDemo;

uses
  Forms,
  MainFrm in 'MainFrm.pas' {Form1},
  DataCompressionU in 'DataCompressionU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
