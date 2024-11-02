unit uBaseTable;
{//----------------------------------------------------------------------------+
    Базовый класс таблицы реализует черезстрочную подсветку и только основные функции. все осальное в наследниках
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
        function    IsCollumnSortable(AColl:Integer):Boolean;
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
    for i:=0 to Length(FAHeaders)-1 do begin
        FAHeaders[i].width:=0;
        FAHeaders[i].calcWidth:=0;
        FAHeaders[i].newWidth:=0;
        FAHeaders[i].ctype:=tcLabel;
        FAHeaders[i].align:=taLeft;
        FAHeaders[i].name:='';
    end;
    //---
    SetLength(FASelRows,FRowCount);
    for i:=0 to Length(FASelRows)-1 do FASelRows[i]:=False;
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
function    TCBaseTable.IsCollumnSortable(AColl:Integer):Boolean;
begin
    Result:=False;
    if( AColl < 0 )then Exit;
    if( AColl >= Length(FAHeaders) )then Exit; 
    if( FAHeaders[AColl].ctype = tcLabel )then Exit;
    if( FAHeaders[AColl].ctype = tcObject )then Exit;
    Result:=True;
end;
//-----------------------------------------------------------------------------+
procedure   TCBaseTable.AddColHeader(Name:ShortString;ColType:TTabColTypes;Align:TTabAllign;Width:Word);
begin
    //--- если количество хидеров больше массива - подгоняем массив
    if( Length(FAHeaders) <= FHdCount )then SetLength(FAHeaders,FHdCount+1);
    //--- заполнили массив хидеров данными
    FAHeaders[FHdCount].name:=Name;
    FAHeaders[FHdCount].ctype:=ColType;
    FAHeaders[FHdCount].align:=Align;
    FAHeaders[FHdCount].width:=Width;
    //--- если мы добавили больше хидеров чем столбцов в таблице расширяем таблицу
    if( Length(FAHeaders) > FTable.ColCount )then begin
        FColCount:=Length(FAHeaders);
        FTable.ColCount:=FColCount;
    end;
    //--- пишем имя хидера в хидер таблицы
    FTable.Cells[FHdCount,0]:=Name;
    //--- навалили счетчик
    inc(FHdCount);
    //--- если стобцов в таблице больше чем надо - обрезаем их
    if( FTable.ColCount > FHdCount )then begin
        FColCount:=FHdCount;
        FTable.ColCount:=FColCount;
    end;
    //--- подгоняем массив хидеров под счетчик (должно быть ни больше ни меньше)
    SetLength(FAHeaders,FHdCount);
    //---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< и теперь вопрос когда обнулять счетчик ???????
end;
//-----------------------------------------------------------------------------+
procedure TCBaseTable.AutoWidth;
var
i,stWidth,nulCount,maxIndex,nulWidth,maxWidth,addWidth,scrlWidth,tabWidth:Integer;
bWidth:Integer;
begin
    stWidth:=0; // общая ширина всех статических столбцов
    nulCount:=0;// счетчик динамических (неопределенных по ширине столбцов)
    maxIndex:=-1;
    maxWidth:=0;
    scrlWidth:=0;
    nulWidth:=0;
    addWidth:=0;// целочисленный остаток ширины таблицы при делении с округлением. добавляем его в последний стобец потом
    //--- находим ширину каждого стобца исходя из общей ширины таблицы отнимая ширину бордюров
    if( FTable.BorderStyle = bsSingle )then bWidth:=1 else bWidth:=0;
    if(( GetWindowLong( FTable.Handle, GWL_STYLE )and WS_VSCROLL ) <> 0 )then scrlWidth:=18;        // ширина полосы вертикального скроллинга если она есть
    tabWidth:=FTable.Width-((bWidth*FTable.ColCount)+bWidth) - scrlWidth;
    stWidth:= Trunc( tabWidth / FTable.ColCount );                                                  // находим среднюю ширину колонки
    addWidth:=tabWidth - ( stWidth * FTable.ColCount );                                             // вычисляем остаток от округления
    //--- если не определили ни одну колонку (пустая таблица)
    if( Length(FAHeaders) < 1 )then begin
        for i:=0 to FTable.ColCount-1 do begin
            FTable.ColWidths[i]:=stWidth;
            if( i = FTable.ColCount-1 )then FTable.ColWidths[i]:=FTable.ColWidths[i] + addWidth;// в проследнюю колонку добавляем остаток, что бы не было дырок
        end;
        Exit;
    end;
    //--- перекладываем статическую ширину на место, подсчитываем количество статичних столбцов
    stWidth:=0;
    for i:=0 to Length(FAHeaders)-1 do begin
        if( FAHeaders[i].width > 0 )then begin
            inc(stWidth,FAHeaders[i].width);
            FAHeaders[i].calcWidth:=FAHeaders[i].width;// если мы определили статическую ширину при объявлении столбца перекладываем ее в высчитанную
        end else Inc(nulCount);
    end;
    //---
    if( nulCount > 0 )then begin  // если есть столбцы со статической шириной, распределяем оставшуюся ширину по динамичесим столбцам
        //---
        nulWidth:=Trunc( (tabWidth-stWidth) / nulCount );// находим ширину для неопределенных стобцов если они есть
        //---
        maxWidth:=0;
        for i:=0 to Length(FAHeaders)-1 do begin
            if( FAHeaders[i].width = 0 )then FAHeaders[i].calcWidth:=nulWidth;                      // распределяем ширину по колонкам
            inc(maxWidth,FAHeaders[i].calcWidth);
        end;
        Inc(FAHeaders[Length(FAHeaders)-1].calcWidth,tabWidth-maxWidth);                                     // добвляем омстаток в последнюю колонку
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
    //--- начисляем
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
            if( FCanSort )and( IsCollumnSortable(FACol) )then begin
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
HM,VM:Integer;
begin
    HM:=5; VM:=Trunc( (FTable.DefaultRowHeight-Abs(FTable.Font.Height)) / 2 );                      
    with FTable.Canvas do begin
        //---черезстрочная подсветка;
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
        //--- центровка текста по горизонтали
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
//----------------------------------------------------+
type TData = record
    intVal:Int64;
    dblVal:Double;
    strVal:ShortString;
    strRow:string;
end; TAData = array of TData;
//----------------------------------------------------+
procedure FastSort(var data:TAData;dType,sortDir:Integer);
var i,j:Integer;
imax,imin,imid:Integer;
arr:TAData;
begin
    if( dType < 0 )then Exit;
    if( dType > 2 )then Exit;
    if( sortDir=0 )then Exit;
    //---
    SetLength(arr,Length(data)*2);
    //--- инициализировали минимум и максимум
    imin :=Length(data);
    imax :=Length(data);
    arr[imin]:=data[0];
    //---
    if( dType = 0 )then begin
        for i:=1 to Length(data)-1 do begin                                                         Application.ProcessMessages;
            if( data[i].intVal < arr[imin].intVal )then begin//если следующий элемент меньше минимума, ставим его ниже и перезаписваем минимум
                Dec(imin);                        // изменили ссылку на минимум
                arr[imin]:=data[i];               // занесли данные
            end else begin
                if( data[i].intVal >= arr[imax].intVal )then begin//если следующий элемент больше максимума
                    inc(imax);                         // изменили ссылку на максимум
                    arr[imax]:=data[i];                // занесли данные
                end else begin
                    imid:=Trunc((imin+imax)/2);        //определили среднее
                    if( data[i].intVal < arr[imid].intVal )then begin // если текущее значение меньше среднего, то ищем в сторону начала
                        for j:=imin to imid do begin
                            if( data[i].intVal >= arr[j].intVal )then begin
                                arr[j-1]:=arr[j];       // передвигаем массив вниз
                            end else begin
                                Dec(imin);                        // изменили ссылку на минимум
                                //---
                                arr[j-1]:=data[i];                         // вставили текущее в освободившуюся ячейку
                                Break;                                     // вышли из цикла
                            end;
                        end;
                    end else begin                         // если больше или равно то в сторону конца
                        for j:=imax downto imid do begin
                            if( data[i].intVal < arr[j].intVal )then begin // если текущее меньше измеренного передвигаем массив вверх
                                arr[j+1]:=arr[j];                          // передвинули массив
                            end else begin
                                inc(imax);                                 // изменили ссылку на максимум
                                //---
                                arr[j+1]:=data[i];                         // вставили текущее в освободившуюся ячейку
                                Break;                                     // вышли из цикла
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
    //---
    if( dType = 1 )then begin
        for i:=1 to Length(data)-1 do begin                                                         Application.ProcessMessages;
            if( data[i].dblVal < arr[imin].dblVal )then begin//если следующий элемент меньше минимума, ставим его ниже и перезаписваем минимум
                Dec(imin);                        // изменили ссылку на минимум
                arr[imin]:=data[i];               // занесли данные
            end else begin
                if( data[i].dblVal > arr[imax].dblVal )then begin//если следующий элемент больше максимума
                    inc(imax);                         // изменили ссылку на максимум
                    arr[imax]:=data[i];                // занесли данные
                end else begin
                    imid:=Trunc((imin+imax)/2)+1;        //определили среднее
                    if( data[i].dblVal < arr[imid].dblVal )then begin // если текущее значение меньше среднего, то ищем в сторону начала
                        for j:=imin to imid do begin
                            if( data[i].dblVal > arr[j].dblVal )then begin
                                arr[j-1]:=arr[j];       // передвигаем массив вниз
                            end else begin
                                Dec(imin);                        // изменили ссылку на минимум
                                //---
                                arr[j-1]:=data[i];                         // вставили текущее в освободившуюся ячейку
                                Break;                                     // вышли из цикла
                            end;
                        end;
                    end else begin                         // если больше или равно то в сторону конца
                        for j:=imax downto imid do begin
                            if( data[i].dblVal < arr[j].dblVal )then begin // если текущее меньше измеренного передвигаем массив вверх
                                arr[j+1]:=arr[j];                          // передвинули массив
                            end else begin
                                inc(imax);                                 // изменили ссылку на максимум
                                //---
                                arr[j+1]:=data[i];                         // вставили текущее в освободившуюся ячейку
                                Break;                                     // вышли из цикла
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
    //---
    if( dType = 2 )then begin
        for i:=1 to Length(data)-1 do begin                                                         Application.ProcessMessages;
            if( data[i].strVal < arr[imin].strVal )then begin//если следующий элемент меньше минимума, ставим его ниже и перезаписваем минимум
                Dec(imin);                        // изменили ссылку на минимум
                arr[imin]:=data[i];               // занесли данные
            end else begin
                if( data[i].strVal >= arr[imax].strVal )then begin//если следующий элемент больше максимума
                    inc(imax);                         // изменили ссылку на максимум
                    arr[imax]:=data[i];                // занесли данные
                end else begin
                    imid:=Trunc((imin+imax)/2);        //определили среднее
                    if( data[i].strVal < arr[imid].strVal )then begin // если текущее значение меньше среднего, то ищем в сторону начала
                        for j:=imin to imid do begin
                            if( data[i].strVal >= arr[j].strVal )then begin
                                arr[j-1]:=arr[j];       // передвигаем массив вниз
                            end else begin
                                Dec(imin);                        // изменили ссылку на минимум
                                //---
                                arr[j-1]:=data[i];                         // вставили текущее в освободившуюся ячейку
                                Break;                                     // вышли из цикла
                            end;
                        end;
                    end else begin                         // если больше или равно то в сторону конца
                        for j:=imax downto imid do begin
                            if( data[i].strVal < arr[j].strVal )then begin // если текущее меньше измеренного передвигаем массив вверх
                                arr[j+1]:=arr[j];                          // передвинули массив
                            end else begin
                                inc(imax);                                 // изменили ссылку на максимум
                                //---
                                arr[j+1]:=data[i];                         // вставили текущее в освободившуюся ячейку
                                Break;                                     // вышли из цикла
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
    //---
    if( sortDir > 0 )then begin
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin];
    end else begin
        for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
    end;
end;
//----------------------------------------------------+
var
i,ii,sz,dType:Integer;
data:TData;
dataArr:TAData;
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
    dType:=0;
    //---
    for i:=1 to sz do begin                                                                         Application.ProcessMessages;
        dataArr[i-1].strRow:=FTable.Rows[i].CommaText;
        case FAHeaders[xPos].ctype of
            tcInt,tcUint : dataArr[i-1].intVal:=StrToInt64Def(FTable.Cells[xpos,i],0);
            tcDate,tcTime,tcDateTime : dataArr[i-1].intVal:=DtmToUnixTime(StrToDateTime(FTable.Cells[xpos,i]));
            tcDbl : begin dataArr[i-1].dblVal:=StrToFloatDef(FTable.Cells[xpos,i],0); dType:=1; end;
        else
            dataArr[i-1].strVal:=FTable.Cells[xpos,i]; dType:=2;
        end;
    end;                                                                                            GetLog('New Start');
    //---
    FastSort(dataArr,dType,sort);
    //---
    for i:=0 to sz-1 do  FTable.Rows[i+1].CommaText:=dataArr[i].strRow;
    FTable.Enabled:=True;
    FTable.SetFocus;                                                                                GetLog('Finish');
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
