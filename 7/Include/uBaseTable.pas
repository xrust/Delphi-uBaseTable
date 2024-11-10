unit uBaseTable;
{//----------------------------------------------------------------------------+
Very Base Table Class For Purpose To Make Small Tables With Objects In Children Classes
}//----------------------------------------------------------------------------+
interface
//-----------------------------------------------------------------------------+
uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
     Dialogs, StdCtrls, Buttons, ExtCtrls, Grids, uNixTime, uLogger;
//-----------------------------------------------------------------------------+
type PStringGrid = ^TStringGrid;
//-----------------------------------------------------------------------------+
type TTabAllign = (taLeft,taRight,taCenter);
type TTabColTypes = (tcLabel,tcObject,tcStr,tcInt,tcUint,tcDbl,tcIpAddr,tcDate,tcTime,tcDateTime);
//-----------------------------------------------------------------------------+
type TRHeader = record
    width   : Word;
    calcWidth : Word;
    newWidth: Word;
    ctype   : TTabColTypes;
    align   : TTabAllign;
    name    : ShortString;
end;
type TAHeaders = array of TRHeader;
//-----------------------------------------------------------------------------+
type TTableMouseEvent = procedure(ACol, ARow: Integer; IsRightClick:Boolean)of object;
//-----------------------------------------------------------------------------+
type TCBaseTable = class
    private
        FClick      : TTableMouseEvent;
        FDblClick   : TTableMouseEvent;
        //---
        procedure   DrawCell(ACol, ARow: Integer; Rect: TRect);
    protected
        FColMinWidth: Word;
        FRowHeigth  : Word;
        FColCount   : Word;
        FRowCount   : Word;
        FHdCount    : Word;
        FAHeaders   : TAHeaders;
        //---
        FMouseX     : Integer;
        FMouseY     : Integer;
        FACol       : Integer;
        FARow       : Integer;
        FLastRow    : Integer;
        //---
        TableColor  : TColor;
        OddColor    : TColor;
        TextColor   : TColor;
        FDateFormat : ShortString;
        FTimeFormat : ShortString;
        //---
        FTable      : PStringGrid;
        //---
        function    RowsCount:Word;
        procedure   FOnDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
        procedure   FOnMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
        procedure   FOnDblClick(Sender: TObject);
    public
        constructor Create(Grid:PStringGrid; ColCount:Word=2; RowCount:Word=5; RowHeight:Word=22);
        procedure   AutoWidth;
        procedure   SetColHeader(Name:ShortString;ColType:TTabColTypes;Align:TTabAllign=taLeft;Width:Word=0);
        procedure   RowAdd(DelimitedText:string;Delimiter:AnsiChar=',');
        procedure   RowInsert(ARow:Word;DelimitedText:string;Delimiter:AnsiChar=',');
        function    Row(Row:Word):TStrings;
        function    Cells(Col:Byte; Row:Word):string;
        function    CellsInt(Col:Byte; Row:Word):Int64;
        function    CellsDbl(Col:Byte; Row:Word):Double;
        procedure   SaveToFile(FileName:string; ShowHeaders:Boolean=False);
        function    LoadFromFile(FileName:string; Delimiter:AnsiChar=','):Integer;
        //---
        property    OnClick : TTableMouseEvent read FClick write FClick;
        property    OnDblClick : TTableMouseEvent read FDblClick write FDblClick;
        //---
        property    DateFormat : ShortString read FDateFormat write FDateFormat;
        property    TimeFormat : ShortString read FTimeFormat write FTimeFormat;
end;
//-----------------------------------------------------------------------------+
implementation
//-----------------------------------------------------------------------------+
constructor TCBaseTable.Create(Grid:PStringGrid; ColCount:Word; RowCount:Word; RowHeight:Word);
var i:Integer;
begin
    FRowHeigth:=RowHeight;
    FColCount:=ColCount;
    FRowCount:=RowCount;
    //---
    FMouseX     :=0;
    FMouseY     :=0;
    FACol       :=0;
    FARow       :=0;
    FLastRow    :=0;
    FColMinWidth:=40;
    //---
    TableColor  :=$FFFFFF;
    OddColor    :=$EEEEEE;//C0C0C0
    TextColor   :=clBlack;
    FDateFormat :='yyyy.mm.dd';
    FTimeFormat :='hh:nn:ss';
    //---
    FHdCount:=0;
    SetLength(FAHeaders,ColCount);
    for i:=0 to Length(FAHeaders)-1 do begin
        FAHeaders[i].width:=0;
        FAHeaders[i].calcWidth:=0;
        FAHeaders[i].newWidth:=0;
        FAHeaders[i].ctype:=tcLabel;
        FAHeaders[i].align:=taLeft;
        FAHeaders[i].name:='';
    end;
    //---
    FTable:=Grid;
    FTable.Options:=[goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect];
    FTable.ColCount:=FColCount;
    FTable.RowCount:=FRowCount;
    FTable.FixedRows:=1;
    FTable.FixedCols:=0;
    FTable.Ctl3D:=False;
    FTable.ScrollBars:=ssNone;
    FTable.DefaultRowHeight:=FRowHeigth;
    FTable.Height:=(FRowHeigth+1) * FRowCount+1;
    //---
    FTable.OnDrawCell:=FOnDrawCell;
    FTable.OnMouseDown:=FOnMouseDown;
    FTable.OnDblClick:=FOnDblClick;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.RowAdd(DelimitedText:string;Delimiter:AnsiChar);
var i:Integer; row:TStringList;
begin
    if( FTable.RowCount < FLastRow + 2 )then FTable.RowCount:=FLastRow + 2;
    try
        //---
        DelimitedText:=StringReplace(DelimitedText,#13,'',[rfReplaceAll, rfIgnoreCase]);
        DelimitedText:=StringReplace(DelimitedText,#10,'_',[rfReplaceAll, rfIgnoreCase]);
        //---
        row:=TStringList.Create;
        row.Delimiter:=Delimiter;
        row.DelimitedText:=DelimitedText;
        row.Text:=StringReplace(row.Text,'_',' ',[rfReplaceAll, rfIgnoreCase]);
        //---
        if( row.Count > FTable.ColCount )then
            for i:=0 to FTable.ColCount do FTable.Cells[i,FLastRow+1]:=Trim(row[i])
            else FTable.Rows[FLastRow+1].AddStrings(row);row.count;
        //---
        row.Free;
    except end;
    inc(FLastRow);
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.RowInsert(ARow:Word;DelimitedText:string;Delimiter:AnsiChar);
var i:Integer; row:TStringList;
begin
    if( FTable.RowCount < ARow + 2 )then FTable.RowCount:=ARow + 2;
    //---
    DelimitedText:=StringReplace(DelimitedText,#13,'',[rfReplaceAll, rfIgnoreCase]);
    DelimitedText:=StringReplace(DelimitedText,#10,'_',[rfReplaceAll, rfIgnoreCase]);
    //---
    try
        row:=TStringList.Create;
        row.Delimiter:=Delimiter;
        row.DelimitedText:=DelimitedText;
        row.Text:=StringReplace(row.Text,'_',' ',[rfReplaceAll, rfIgnoreCase]);
        //---
        if( row.Count > FTable.ColCount )then
            for i:=0 to FTable.ColCount do FTable.Cells[i,FLastRow+1]:=Trim(row[i])
            else FTable.Rows[FLastRow+1].AddStrings(row);row.count;
        //---
        FTable.Rows[ARow+1].AddStrings(row);
        row.Free;
    except end;
    FLastRow:=RowsCount;
end;
//-----------------------------------------------------------------------------+
function    TCBaseTable.Row(Row:Word):TStrings;
begin
    if( Row >= RowsCount )then Row:=RowsCount-1;
    Result:=FTable.Rows[Row+1];
end;
//-----------------------------------------------------------------------------+
function    TCBaseTable.Cells(Col:Byte; Row:Word):string;
begin
    if( Row >= RowsCount )then Row:=RowsCount-1;
    if( Col >= FTable.ColCount )then Col:=FTable.ColCount-1;
    if( FAHeaders[Col].ctype = tcObject )then Exit;
    Result:=FTable.Cells[Col,Row];
end;
//-----------------------------------------------------------------------------+
function    TCBaseTable.CellsInt(Col:Byte; Row:Word):Int64;begin Result:=StrToInt64Def(Cells(Col,Row),0);end;
//-----------------------------------------------------------------------------+
function    TCBaseTable.CellsDbl(Col:Byte; Row:Word):Double;begin Result:=StrToFloatDef(Cells(Col,Row),0);end;
//-----------------------------------------------------------------------------+
function    TCBaseTable.LoadFromFile(FileName:string;Delimiter:AnsiChar):Integer;
var list:TStringList;i:Integer;
begin
    Result:=0;
    if( not FileExists(FileName) )then Exit;
    list:=TStringList.Create;
    list.LoadFromFile(FileName);
    //---
    FTable.RowCount:=2;
    FTable.Rows[1].Clear;
    FLastRow:=0;
    FTable.RowCount:=list.Count+1;
    //---
    for i:=0 to list.Count-1 do RowAdd(StringReplace(list[i],' ','_',[rfReplaceAll, rfIgnoreCase]),Delimiter);
    //---
    list.Free;
    Result:=RowsCount;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.SaveToFile(FileName:string; ShowHeaders:Boolean=False);
var list:TStringList;i,c:Integer;
begin
    if( ShowHeaders )then c:=0 else c:=1;
    list:=TStringList.Create;
    for i:=c to FTable.RowCount-1 do list.Add(FTable.Rows[i].CommaText);
    list.SaveToFile(FileName);
    list.Free;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.SetColHeader(Name:ShortString;ColType:TTabColTypes;Align:TTabAllign;Width:Word);
begin
    if( Length(FAHeaders) <= FHdCount )then SetLength(FAHeaders,FHdCount+1);
    //---
    FAHeaders[FHdCount].name:=Name;
    FAHeaders[FHdCount].ctype:=ColType;
    FAHeaders[FHdCount].align:=Align;
    FAHeaders[FHdCount].width:=Width;
    //---
    if( Length(FAHeaders) > FTable.ColCount )then begin
        FColCount:=Length(FAHeaders);
        FTable.ColCount:=FColCount;
    end;
    //---
    FTable.Cells[FHdCount,0]:=Name;
    inc(FHdCount);
    //---
    if( FTable.ColCount > FHdCount )then begin
        FColCount:=FHdCount;
        FTable.ColCount:=FColCount;
    end;
    //---
    SetLength(FAHeaders,FHdCount);
end;
//-----------------------------------------------------------------------------+
procedure TCBaseTable.AutoWidth;
var
i,stWidth,nulCount,maxIndex,nulWidth,maxWidth,addWidth,scrlWidth,tabWidth:Integer;
bWidth:Integer;
begin
    stWidth:=0; // обща€ ширина всех статических столбцов
    nulCount:=0;// счетчик динамических (неопределенных по ширине столбцов)
    maxIndex:=-1;
    maxWidth:=0;
    scrlWidth:=0;
    nulWidth:=0;
    addWidth:=0;// целочисленный остаток ширины таблицы при делении с округлением. добавл€ем его в последний стобец потом
    //--- находим ширину каждого стобца исход€ из общей ширины таблицы отнима€ ширину бордюров
    if( FTable.BorderStyle = bsSingle )then bWidth:=1 else bWidth:=0;
    if(( GetWindowLong( FTable.Handle, GWL_STYLE )and WS_VSCROLL ) <> 0 )then scrlWidth:=18;        // ширина полосы вертикального скроллинга если она есть
    tabWidth:=FTable.Width-((bWidth*FTable.ColCount)+bWidth) - scrlWidth;
    stWidth:= Trunc( tabWidth / FTable.ColCount );                                                  // находим среднюю ширину колонки
    addWidth:=tabWidth - ( stWidth * FTable.ColCount );                                             // вычисл€ем остаток от округлени€
    //--- если не определили ни одну колонку (пуста€ таблица)
    if( Length(FAHeaders) < 1 )then begin
        for i:=0 to FTable.ColCount-1 do begin
            FTable.ColWidths[i]:=stWidth;
            if( i = FTable.ColCount-1 )then FTable.ColWidths[i]:=FTable.ColWidths[i] + addWidth;// в проследнюю колонку добавл€ем остаток, что бы не было дырок
        end;
        Exit;
    end;
    //--- перекладываем статическую ширину на место, подсчитываем количество статичних столбцов
    stWidth:=0;
    for i:=0 to Length(FAHeaders)-1 do begin
        if( FAHeaders[i].width > 0 )then begin
            inc(stWidth,FAHeaders[i].width);
            FAHeaders[i].calcWidth:=FAHeaders[i].width;// если мы определили статическую ширину при объ€влении столбца перекладываем ее в высчитанную
        end else Inc(nulCount);
    end;
    //---
    if( nulCount > 0 )then begin  // если есть столбцы со статической шириной, распредел€ем оставшуюс€ ширину по динамичесим столбцам
        //---
        nulWidth:=Trunc( (tabWidth-stWidth) / nulCount );// находим ширину дл€ неопределенных стобцов если они есть
        //---
        maxWidth:=0;
        for i:=0 to Length(FAHeaders)-1 do begin
            if( FAHeaders[i].width = 0 )then FAHeaders[i].calcWidth:=nulWidth;                      // распредел€ем ширину по колонкам
            inc(maxWidth,FAHeaders[i].calcWidth);
        end;
        Inc(FAHeaders[Length(FAHeaders)-1].calcWidth,tabWidth-maxWidth);                                     // добвл€ем омстаток в последнюю колонку
        //---
    end else begin
        if( stWidth <> 0 )then nulWidth:=(tabWidth-stWidth);
        if( nulWidth <> 0 )then begin
            for i:=0 to Length(FAHeaders)-1 do begin
                if( FAHeaders[i].width > maxWidth )then begin
                    maxWidth:= FAHeaders[i].width;
                    maxIndex:=i;
                end;
            end;
            if( maxIndex >= 0)then FAHeaders[maxIndex].calcWidth:=FAHeaders[maxIndex].width+nulWidth;
        end;
    end;
    //--- начисл€ем
    for i:=0 to FTable.ColCount-1 do FTable.ColWidths[i]:=FAHeaders[i].calcWidth;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.FOnMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var i:Integer; crd:TGridCoord;
begin
    crd:=FTable.MouseCoord(X,Y);
    //---
    FMouseX:=X;
    FMouseY:=Y;
    //---
    FACol:=crd.X;
    FARow:=crd.Y;
    //---
    if( Button = mbLeft )then if( Assigned(FClick) )then FClick(FACol,FARow-1,False);
    if( Button = mbRight )then if( Assigned(FClick) )then FClick(FACol,FARow-1,True);

end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.FOnDblClick(Sender: TObject);
begin
    if( FARow = 0 )then Exit;
    if( Assigned(FDblClick) )then FDblClick(FACol,FARow-1,False);
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.FOnDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
    DrawCell(ACol,ARow,Rect);
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.DrawCell(ACol, ARow: Integer; Rect: TRect);
var
HM,VM:Integer;
begin
    HM:=5; VM:=Trunc( (FTable.DefaultRowHeight-Abs(FTable.Font.Height)) / 2 );                      
    with FTable.Canvas do begin
        //---черезстрочна€ подсветка;
        if( ARow > 0 )then begin
            if( not Odd(ARow) )then begin
                Brush.Color:=OddColor;
            end else begin
                Brush.Color:=TableColor;
            end;
            //---
            SetTextColor(Handle,TextColor);
        end else Brush.Color := Ftable.FixedColor;
        //--- центровка текста по горизонтали
        FillRect(Rect);
        SetBkMode(Handle, TRANSPARENT);
        if( ACol < Length( FAHeaders ) )then begin
            case  FAHeaders[ACol].align of
                taLeft : begin
                    SetTextAlign(Handle,TA_LEFT);
                    TextOut(Rect.Left+HM,Rect.Top+VM,Ftable.Cells[ACol,ARow]);
                end;
                taRight: begin
                    SetTextAlign(Handle,TA_RIGHT);
                    TextOut(Rect.Right-HM,Rect.Top+VM,Ftable.Cells[ACol,ARow]);
                end;
                taCenter:begin
                    SetTextAlign(Handle,TA_CENTER);
                    TextOut(Rect.Left+(Rect.Right - Rect.Left)div 2,Rect.Top+VM,Ftable.Cells[ACol,ARow]);
                end;
            end;
        end;
    end;
end;
//-----------------------------------------------------------------------------+
function    TCBaseTable.RowsCount:Word;begin Result:=FTable.RowCount-1; end;
//-----------------------------------------------------------------------------+
end.
