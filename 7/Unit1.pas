unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, uLogger, uBaseTable;

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
    Table : TCBaseTable;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
    Table := TCBaseTable.Create(@StringGrid1,5,50);
    Table.ScrollBarType:=ssVertical;
    Table.OnClick:=OnTableClick;
    Table.OnDblClick:=OnTableDblClick;

    Table.AddColHeader('DateTime',tcDateTime);
    Table.AddColHeader('Open',tcDbl);
    Table.AddColHeader('High',tcDbl);
    Table.AddColHeader('Low',tcDbl);
    Table.AddColHeader('Close',tcDbl);
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
