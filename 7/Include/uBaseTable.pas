unit uBaseTable;
{//----------------------------------------------------------------------------+
    ������� ����� ������� ��������� ������������� ��������� � ������ �������� �������. ��� �������� � �����������
}//----------------------------------------------------------------------------+
interface
//-----------------------------------------------------------------------------+
uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
     Dialogs, StdCtrls, Buttons, ExtCtrls, Grids, uNixTime, uLogger;
//-----------------------------------------------------------------------------+
type PStringGrid = ^TStringGrid;
//-----------------------------------------------------------------------------+
type TTabAllign = (taLeft,taRight,taCenter);
type TTabColTypes = (tcLabel,tcStr,tcInt,tcUint,tcDbl,tcIpAddr,tcDate,tcTime,tcDateTime);
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
        //--- sorting
        FCanSort    : Boolean;
        FSortPos    : Integer;
        FSortDir    : Integer;
        //---
        SelectedRow : Integer;
        FSelectable : Boolean;
        FScrollStyle: TScrollStyle;
        //---
        FClick      : TTableMouseEvent;
        FDblClick   : TTableMouseEvent;
        //---
        procedure   SetSortable(sort:Boolean);
        procedure   SetScroll(ScrollStyle:TScrollStyle);
        procedure   SetSelectable(SetSelectable:Boolean);
        //---
        procedure   DrawArrow(up_dn:Integer; Rect:TRect; ARight:Boolean=False);
        procedure   DrawCell(ACol, ARow: Integer; Rect: TRect);
        procedure   AutoWithWhenCollWithChanged;
        procedure   Sort(xPos,sort:Integer);
    protected
        FColMinWidth: Word;
        FRowHeigth  : Word;
        FColCount   : Word;
        FRowCount   : Word;
        FHdCount    : Word;
        FAHeaders   : TAHeaders;
        FASelRows   : array of Boolean;
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
        SelColor    : TColor;
        //---
        FDateFormat : ShortString;
        FTimeFormat : ShortString;
        //---
        FCellSelect : Boolean;
        //---
        FTable      : PStringGrid;
        //---
        function    RowsCount:Word;
        procedure   FOnDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
        procedure   FOnMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
        procedure   FOnMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
        procedure   FOnMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
        procedure   FOnMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
        procedure   FOnDblClick(Sender: TObject);
    public
        constructor Create(Grid:PStringGrid; ColCount:Word=2; RowCount:Word=5; RowHeight:Word=22);
        procedure   AutoWidth;
        procedure   AddColHeader(Name:ShortString;ColType:TTabColTypes;Align:TTabAllign=taLeft;Width:Word=0);
        procedure   RowAdd(DelimitedText:string;Delimiter:AnsiChar=',');
        procedure   RowInsert(ARow:Word;DelimitedText:string;Delimiter:AnsiChar=',');
        procedure   SaveToFile(FileName:string; ShowHeaders:Boolean=False);
        function    LoadFromFile(FileName:string; Delimiter:AnsiChar=','):Integer;
        //---
        property    OnClick : TTableMouseEvent read FClick write FClick;
        property    OnDblClick : TTableMouseEvent read FDblClick write FDblClick;
        //---
        property    ScrollBarType : TScrollStyle read FScrollStyle write SetScroll default ssNone;
        property    Selectable : Boolean read FSelectable write SetSelectable default False;
        property    CanSort : Boolean read FCanSort write SetSortable default True;
        property    DateFormat : ShortString read FDateFormat write FDateFormat;
        property    TimeFormat : ShortString read FTimeFormat write FTimeFormat;
end;
//-----------------------------------------------------------------------------+
implementation
//-----------------------------------------------------------------------------+
constructor TCBaseTable.Create(Grid:PStringGrid; ColCount:Word; RowCount:Word; RowHeight:Word);
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
    FCanSort    := True;
    FSortPos    :=0;
    FSortDir    :=0;
    //---
    TableColor  :=$FFFFFF;
    OddColor    :=$EEEEEE;//C0C0C0
    TextColor   :=clBlack;
    SelColor    :=$FEF1E1;
    FCellSelect :=False;
    //---
    FDateFormat := 'yyyy.mm.dd';
    FTimeFormat := 'hh:nn:ss';
    //---
    FHdCount:=0;
    SetLength(FAHeaders,ColCount);
    //---
    SetLength(FASelRows,FRowCount);
    //---
    FTable:=Grid;
    FTable.Options:=[goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect, goColSizing];
    FTable.ColCount:=FColCount;
    FTable.RowCount:=FRowCount;
    FTable.FixedRows:=1;
    FTable.FixedCols:=0;
    FTable.Ctl3D:=False;
    FTable.ScrollBars:=FScrollStyle;
    FTable.DefaultRowHeight:=FRowHeigth;
    FTable.Height:=(FRowHeigth+1) * FRowCount+1;
    //---
    FTable.OnDrawCell:=FOnDrawCell;
    FTable.OnMouseDown:=FOnMouseDown;
    FTable.OnMouseUp:=FOnMouseUp;
    FTable.OnMouseWheelDown:=FOnMouseWheelDown;
    FTable.OnMouseWheelUp:=FOnMouseWheelUp;
    FTable.OnDblClick:=FOnDblClick;
    //---
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.RowAdd(DelimitedText:string;Delimiter:AnsiChar);var row:TStringList;
begin
    if( FTable.RowCount < FLastRow + 2 )then FTable.RowCount:=FLastRow + 2;
    row:=TStringList.Create;
    row.Delimiter:=Delimiter;
    row.DelimitedText:=DelimitedText;
    row.Text:=StringReplace(row.Text,'_',' ',[rfReplaceAll, rfIgnoreCase]);
    FTable.Rows[FLastRow+1].AddStrings(row);
    row.Free;
    inc(FLastRow);
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.RowInsert(ARow:Word;DelimitedText:string;Delimiter:AnsiChar);var row:TStringList;
begin
    if( FTable.RowCount < ARow + 2 )then begin
        FTable.RowCount:=ARow + 2;
    end;    
    row:=TStringList.Create;
    row.Delimiter:=Delimiter;
    row.DelimitedText:=DelimitedText;
    row.Text:=StringReplace(row.Text,'_',' ',[rfReplaceAll, rfIgnoreCase]);
    FTable.Rows[ARow+1].AddStrings(row);
    row.Free;
    FLastRow:=RowsCount;
end;
//-----------------------------------------------------------------------------+
function    TCBaseTable.LoadFromFile(FileName:string;Delimiter:AnsiChar):Integer;
var list:TStringList;i:Integer;str:string;
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
var list:TStringList;i,c:Integer; str:string;
begin
    if( ShowHeaders )then c:=0 else c:=1;
    list:=TStringList.Create;
    for i:=c to FTable.RowCount-1 do list.Add(FTable.Rows[i].CommaText);
    list.SaveToFile(FileName);
    list.Free;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.AddColHeader(Name:ShortString;ColType:TTabColTypes;Align:TTabAllign;Width:Word);
begin
    //--- ���� ���������� ������� ������ ������� - ��������� ������
    if( Length(FAHeaders) <= FHdCount )then SetLength(FAHeaders,FHdCount+1);
    //--- ��������� ������ ������� �������
    FAHeaders[FHdCount].name:=Name;
    FAHeaders[FHdCount].ctype:=ColType;
    FAHeaders[FHdCount].align:=Align;
    FAHeaders[FHdCount].width:=Width;
    //--- ���� �� �������� ������ ������� ��� �������� � ������� ��������� �������
    if( Length(FAHeaders) > FTable.ColCount )then begin
        FColCount:=Length(FAHeaders);
        FTable.ColCount:=FColCount;
    end;
    //--- ����� ��� ������ � ����� �������
    FTable.Cells[FHdCount,0]:=Name;
    //--- �������� �������
    inc(FHdCount);
    //--- ���� ������� � ������� ������ ��� ���� - �������� ��
    if( FTable.ColCount > FHdCount )then begin
        FColCount:=FHdCount;
        FTable.ColCount:=FColCount;
    end;
    //--- ��������� ������ ������� ��� ������� (������ ���� �� ������ �� ������)
    SetLength(FAHeaders,FHdCount);
    //---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< � ������ ������ ����� �������� ������� ???????
end;
//-----------------------------------------------------------------------------+
procedure TCBaseTable.AutoWidth;
var
i,stWidth,nulCount,maxIndex,nulWidth,maxWidth,addWidth,scrlWidth,tabWidth:Integer;
bWidth:Integer;
begin
    stWidth:=0; // ����� ������ ���� ����������� ��������
    nulCount:=0;// ������� ������������ (�������������� �� ������ ��������)
    maxIndex:=-1;
    maxWidth:=0;
    scrlWidth:=0;
    nulWidth:=0;
    addWidth:=0;// ������������� ������� ������ ������� ��� ������� � �����������. ��������� ��� � ��������� ������ �����
    //--- ������� ������ ������� ������ ������ �� ����� ������ ������� ������� ������ ��������
    if( FTable.BorderStyle = bsSingle )then bWidth:=1 else bWidth:=0;
    if(( GetWindowLong( FTable.Handle, GWL_STYLE )and WS_VSCROLL ) <> 0 )then scrlWidth:=18;        // ������ ������ ������������� ���������� ���� ��� ����
    tabWidth:=FTable.Width-((bWidth*FTable.ColCount)+bWidth) - scrlWidth;
    stWidth:= Trunc( tabWidth / FTable.ColCount );                                                  // ������� ������� ������ �������
    addWidth:=tabWidth - ( stWidth * FTable.ColCount );                                             // ��������� ������� �� ����������
    //--- ���� �� ���������� �� ���� ������� (������ �������)
    if( Length(FAHeaders) < 1 )then begin
        for i:=0 to FTable.ColCount-1 do begin
            FTable.ColWidths[i]:=stWidth;
            if( i = FTable.ColCount-1 )then FTable.ColWidths[i]:=FTable.ColWidths[i] + addWidth;// � ���������� ������� ��������� �������, ��� �� �� ���� �����
        end;
        Exit;
    end;
    //--- ������������� ����������� ������ �� �����, ������������ ���������� ��������� ��������
    stWidth:=0;
    for i:=0 to Length(FAHeaders)-1 do begin
        if( FAHeaders[i].width > 0 )then begin
            inc(stWidth,FAHeaders[i].width);
            FAHeaders[i].calcWidth:=FAHeaders[i].width;// ���� �� ���������� ����������� ������ ��� ���������� ������� ������������� �� � �����������
        end else Inc(nulCount);
    end;
    //---
    if( nulCount > 0 )then begin  // ���� ���� ������� �� ����������� �������, ������������ ���������� ������ �� ����������� ��������
        //---
        nulWidth:=Trunc( (tabWidth-stWidth) / nulCount );// ������� ������ ��� �������������� ������� ���� ��� ����
        //---
        maxWidth:=0;
        for i:=0 to Length(FAHeaders)-1 do begin
            if( FAHeaders[i].width = 0 )then FAHeaders[i].calcWidth:=nulWidth;                      // ������������ ������ �� ��������
            inc(maxWidth,FAHeaders[i].calcWidth);
        end;
        Inc(FAHeaders[Length(FAHeaders)-1].calcWidth,tabWidth-maxWidth);                                     // �������� �������� � ��������� �������
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
    //--- ���������
    for i:=0 to FTable.ColCount-1 do FTable.ColWidths[i]:=FAHeaders[i].calcWidth;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.AutoWithWhenCollWithChanged;
var
i,chCol,chDiff:Integer;
hasChange:Boolean;
begin
    hasChange:=False;
    for i:=0 to FTable.ColCount-1 do begin
        if( FTable.ColWidths[i] <> FAHeaders[i].calcWidth )then begin
            chCol:=i;
            chDiff:=FAHeaders[i].calcWidth-FTable.ColWidths[i];
            hasChange:=True;
            Break;
        end;
    end;
    //---
    if( hasChange )then begin
        if( chCol < FTable.ColCount-1 )then begin
            if( FTable.ColWidths[chCol] >= FColMinWidth )and(FAHeaders[chCol+1].calcWidth + chDiff >= FColMinWidth )then begin
                FAHeaders[chCol].calcWidth:=FTable.ColWidths[chCol];
                FAHeaders[chCol+1].calcWidth:=FAHeaders[chCol+1].calcWidth + chDiff;
            end;
        end;
        for i:=0 to FTable.ColCount-1 do FTable.ColWidths[i]:=FAHeaders[i].calcWidth;
    end;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.FOnMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    AutoWithWhenCollWithChanged;
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
    SelectedRow:=FARow-1;                                                                             
    //---
    if( FARow = 0 )then begin
        if( Button = mbLeft )then begin
            if( FCanSort )then begin
                if( FSortPos <> FACol )then begin
                    FSortDir:=1;
                end else begin
                    if( FSortDir = 0 )then FSortDir:=-1;
                    FSortDir:=-FSortDir;
                end;
                FSortPos:=FACol;
                //---
                for i:=0 to FTable.ColCount-1 do  DrawCell(i,0,Ftable.CellRect(i,0));
                Ftable.Refresh;
                //---
                Sort(FSortPos,FSortDir);
            end;
        end;
        if( Button = mbRight )then if( Assigned(FClick) )then FClick(FACol,FARow-1,True);
    end else begin
        if( Button = mbLeft )then if( Assigned(FClick) )then FClick(FACol,FARow-1,False);
        if( Button = mbRight )then if( Assigned(FClick) )then FClick(FACol,FARow-1,True);
    end;
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
procedure   TCBaseTable.FOnMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
    SelectedRow:=FTable.Row;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.FOnMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
    SelectedRow:=FTable.Row;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.DrawCell(ACol, ARow: Integer; Rect: TRect);
var
i,HM,VM:Integer;
arrow:TGraphic;
ptarr:array [0..3] of TPoint;
begin
    HM:=5; VM:=Trunc( (FTable.DefaultRowHeight-Abs(FTable.Font.Height)) / 2 );                      
    with FTable.Canvas do begin
        //---������������� ���������;
        if( ARow > 0 )then begin
            if( ARow <> FTable.Row )then begin
            if( not Odd(ARow) )then begin
                Brush.Color:=OddColor;
            end else begin
                Brush.Color:=TableColor;
            end;
            end else begin
                if( SelectedRow > 0 ) then Brush.Color:=SelColor else Brush.Color:=TableColor;
            end;
            //---
            SetTextColor(Handle,TextColor);
        end else Brush.Color := Ftable.FixedColor;
        //--- ��������� ������ �� �����������
        FillRect(Rect);
        SetBkMode(Handle, TRANSPARENT);
        if( ACol < Length( FAHeaders ) )then begin
            case  FAHeaders[ACol].align of
                taLeft : begin
                    if( ARow = 0 )and( ACol = FSortPos )then DrawArrow(FSortDir,Rect);
                    SetTextAlign(Handle,TA_LEFT);
                    TextOut(Rect.Left+HM,Rect.Top+VM,Ftable.Cells[ACol,ARow]);
                end;
                taRight: begin
                    if( ARow = 0 )and( ACol = FSortPos )then DrawArrow(FSortDir,Rect,True);
                    SetTextAlign(Handle,TA_RIGHT);
                    TextOut(Rect.Right-HM,Rect.Top+VM,Ftable.Cells[ACol,ARow]);
                end;
                taCenter:begin
                    if( ARow = 0 )and( ACol = FSortPos )then DrawArrow(FSortDir,Rect);
                    SetTextAlign(Handle,TA_CENTER);
                    TextOut(Rect.Left+(Rect.Right - Rect.Left)div 2,Rect.Top+VM,Ftable.Cells[ACol,ARow]);
                end;
            end;
        end;
    end;
    //---
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.DrawArrow(up_dn:Integer; Rect:TRect; ARight:Boolean);//9X5
var
oldMode:TPenMode;
ptarr:array [0..3] of TPoint;
hmdl,wmdl:Integer;
begin
    if( not FCanSort )then Exit;
    //---
    hmdl:=Rect.Top+Trunc((Rect.Bottom-rect.Top)/2);
    wmdl:=Rect.Right-Trunc((Rect.Bottom-rect.Top)/2);
    if( ARight )then wmdl:=Rect.Left+Trunc((Rect.Bottom-rect.Top)/2);
    //---
    with FTable.Canvas do begin
        oldMode:=Pen.Mode;
        //---
        Pen.Mode:=pmBlack;
        if( up_dn > 0 )then begin
            with Rect do begin
                ptarr[0] := Point(wmdl,hmdl-2);
                ptarr[1] := Point(wmdl-4, hmdl+2);
                ptarr[2] := Point(wmdl+4,hmdl+2);
                ptarr[3] := ptarr[0];
                Polygon(ptarr);
            end;
        end else if( up_dn < 0 )then begin
            with Rect do begin
                ptarr[0] := Point(wmdl,hmdl+2);
                ptarr[1] := Point(wmdl-4, hmdl-2);
                ptarr[2] := Point(wmdl+4,hmdl-2);
                ptarr[3] := ptarr[0];
                Polygon(ptarr);
            end;
        end;
        //---
        Pen.Mode:=oldMode;
        SetTextColor(Handle,TextColor);
    end;
end;
//-----------------------------------------------------------------------------+
procedure TCBaseTable.Sort(xPos,sort:Integer);
type TData = record
    intVal:Int64;
    dblVal:Double;
    strVal:ShortString;
    strRow:string;
end; TAData = array of TData;
//----------------------------------------------------+
var
i,ii,sz:Integer;
data:TData;
dataArr:TAData;
dtmFormat:TFormatSettings;
//----
begin
    ShortDateFormat:=FDateFormat;
    LongTimeFormat:=FTimeFormat;
    DecimalSeparator:='.';
    //---
    if( sort = 0 )then Exit;
    if( FTable.RowCount < 3 )then Exit;
    sz:=FTable.RowCount-1;
    SetLength(dataArr,sz);
    FTable.Enabled:=False;
    //---
    for i:=1 to sz do begin
        dataArr[i-1].strRow:=FTable.Rows[i].CommaText;
        case FAHeaders[xPos].ctype of
            tcInt,tcUint : dataArr[i-1].intVal:=StrToInt64Def(FTable.Cells[xpos,i],0);
            tcDate,tcTime,tcDateTime : dataArr[i-1].intVal:=DtmToUnixTime(StrToDateTime(FTable.Cells[xpos,i]));
            tcDbl : dataArr[i-1].dblVal:=StrToFloatDef(FTable.Cells[xpos,i],0);
        else
            dataArr[i-1].strVal:=FTable.Cells[xpos,i];
        end;
    end;
    //---
    if( FAHeaders[xPos].ctype = tcDbl ) then begin
        for i:=0 to Length(dataArr)-1 do begin
            for ii:=i+1 to Length(dataArr)-1 do begin
                if( sort >= 0 )then begin
                    if( dataArr[i].dblVal > dataArr[ii].dblVal )then begin
                        data:=dataArr[ii];
                        dataArr[ii]:=dataArr[i];
                        dataArr[i]:=data;
                    end;
                end else begin
                    if( dataArr[i].dblVal < dataArr[ii].dblVal )then begin
                        data:=dataArr[ii];
                        dataArr[ii]:=dataArr[i];
                        dataArr[i]:=data;
                    end;
                end;
            end;
        end;
    end else begin
        if( FAHeaders[xPos].ctype = tcStr )or( FAHeaders[xPos].ctype = tclabel )  then begin
            for i:=0 to Length(dataArr)-1 do begin
                for ii:=i+1 to Length(dataArr)-1 do begin
                    if( sort >= 0 )then begin
                        if( CompareStr(dataArr[i].strVal,dataArr[ii].strVal) > 0 )then begin
                            data:=dataArr[ii];
                            dataArr[ii]:=dataArr[i];
                            dataArr[i]:=data;
                        end;
                    end else begin
                        if( CompareStr(dataArr[i].strVal,dataArr[ii].strVal) < 0 )then begin
                            data:=dataArr[ii];
                            dataArr[ii]:=dataArr[i];
                            dataArr[i]:=data;
                        end;
                    end;
                end;
            end;
        end else begin
            for i:=0 to Length(dataArr)-1 do begin
                for ii:=i+1 to Length(dataArr)-1 do begin
                    if( sort >= 0 )then begin
                        if( dataArr[i].intVal > dataArr[ii].intVal )then begin
                            data:=dataArr[ii];
                            dataArr[ii]:=dataArr[i];
                            dataArr[i]:=data;
                        end;
                    end else begin
                        if( dataArr[i].intVal < dataArr[ii].intVal )then begin
                            data:=dataArr[ii];
                            dataArr[ii]:=dataArr[i];
                            dataArr[i]:=data;
                        end;
                    end;
                end;
            end;
        end;
    end;
    //---
    for i:=0 to sz-1 do  FTable.Rows[i+1].CommaText:=dataArr[i].strRow;
    FTable.Enabled:=True;
    FTable.SetFocus;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.SetScroll(ScrollStyle:TScrollStyle);begin FTable.ScrollBars:=ScrollStyle;end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.SetSelectable(SetSelectable:Boolean);begin FSelectable:=SetSelectable;end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.SetSortable(sort:Boolean);begin FCanSort:=sort; end;
//-----------------------------------------------------------------------------+
function    TCBaseTable.RowsCount:Word;begin Result:=FTable.RowCount-1; end;
//-----------------------------------------------------------------------------+
end.
