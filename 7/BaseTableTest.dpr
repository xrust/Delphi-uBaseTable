program BaseTableTest;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  uLogger in 'Include\uLogger.pas',
  uBaseTable in 'Include\uBaseTable.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
