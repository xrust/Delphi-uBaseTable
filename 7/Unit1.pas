unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, uLogger, uBaseTable, uCommonTable;

type
  TForm1 = class(TForm)
    Log: TMemo;
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
  public
    procedure OnTableClick(ACol, ARow: Integer; IsRightClick:Boolean);
    procedure OnTableDblClick(ACol, ARow: Integer; IsRightClick:Boolean);
  end;

var Form1: TForm1;
    Table : TCCommonTable;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
    Table := TCCommonTable.Create(@StringGrid1,5,50);
    Table.ScrollBarType:=ssVertical;
    Table.OnClick:=OnTableClick;
    Table.OnDblClick:=OnTableDblClick;

    Table.SetColHeader('DateTime',tcDateTime);
    Table.SetColHeader('Open',tcDbl);
    Table.SetColHeader('High',tcDbl);
    Table.SetColHeader('Low',tcDbl);
    Table.SetColHeader('Close',tcDbl);
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
    Table.LoadFromFile('XAUUSD.csv',';');
    Table.AutoWidth;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
//
end;

procedure TForm1.FormResize(Sender: TObject);
begin
    Table.AutoWidth;
end;

procedure TForm1.OnTableClick(ACol, ARow: Integer; IsRightClick:Boolean);
begin
    if( IsRightClick )then PrintLn(['Right Click',' Collumn : ',ACol,' Row : ',ARow])else PrintLn(['Left Click',' Collumn : ',ACol,' Row : ',ARow]);
end;

procedure TForm1.OnTableDblClick(ACol, ARow: Integer; IsRightClick:Boolean);
begin
    PrintLn(['Double Click',' Collumn : ',ACol,' Row : ',ARow]);
end;

end.
