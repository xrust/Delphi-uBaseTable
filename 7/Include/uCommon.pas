unit uCommon;
{//----------------------------------------------------------------------------+
    Set Of Common Functions    
}//----------------------------------------------------------------------------+
interface
//-----------------------------------------------------------------------------+
uses Windows, Messages, SysUtils, Variants, Classes, Controls, Forms, StdCtrls, ExtCtrls, WinSock, Mask;
//-----------------------------------------------------------------------------+
type TTypeOfVars = (tvString,tvUint,tvInt,tvDouble,tvIpAddr,tvDate,tvTime,tvDateTime);
//-----------------------------------------------------------------------------+
procedure CheckKeyPress(TypeVar:TTypeOfVars; WinComp:TComponent; var Key: Char);
//-----------------------------------------------------------------------------+
function  HaveDir(const fn:string; const create:boolean=true):boolean;
function  GetLocalIP: String;
function  VarToString(Value: Variant):String;overload;
function  VarToStringF(Value: Variant; Digits:Integer=8):String;overload
procedure ArrSort(var data:array of Integer; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var data:array of Int64; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var data:array of Double; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var data:array of string; sortByDecrement:Boolean=False);overload;
//-----------------------------------------------------------------------------+
implementation
//-----------------------------------------------------------------------------+
procedure CheckKeyPress(TypeVar:TTypeOfVars; WinComp:TComponent; var Key: Char);
var text:string;
begin
    //---
    if( WinComp.ClassType = TEdit )then text:=TEdit(WinComp).Text;
    if( WinComp.ClassType = TMaskEdit )then text:=TMaskEdit(WinComp).Text;
    if( WinComp.ClassType = TLabeledEdit )then text:=TEdit(TLabeledEdit).Text;
    if( WinComp.ClassType = TComboBox )then text:=TEdit(TComboBox).Text;
    //---
    case( TypeVar )of
        tvUint : begin
            case Key of
                '0'..'9':;
                #8:;
            else
                key := #0;
            end;
        end;
        tvInt : begin
            case Key of
                '0'..'9':;
                '-':if( Length(Text)>0 )then Key:=#0;
                #8:;
            else
                key := #0;
            end;
        end;
        tvDouble :begin
            case Key of
            '0'..'9':;
            '-':if( Length(Text)>0 )then Key:=#0;
            '.':begin
                    if( Length(Text)<1 )then Key:=#0;
                    if( Text = '-' )and( Length(Text) = 1 )then Key:=#0;
                    if( Pos('.',Text) > 0 )then Key:=#0;
                end;
            #8:;
            else
                key := #0;
            end;
        end;
        tvIpAddr :begin
            case key of
                '0'..'9': ; // цифры
                #8: ; // забой
                '.':;
                '*':
            else
                key := #0;
            end;
        end;
    end;
end;
//-----------------------------------------------------------------------------+
function VarToString(Value: Variant):String;
begin
    Result:='';
    DecimalSeparator:='.';
    try
        case TVarData(Value).VType of
            varByte,
            varShortInt,
            varSmallInt,
            varInteger,
            varWord,
            varLongWord,
            varInt64    : Result := IntToStr(Value);
            varSingle,
            varDouble,
            varCurrency : Result := FloatToStr(Value);//,ffFixed,20,10);
            varDate     : Result := FormatDateTime('yyyy.mm.dd hh:nn:ss', Value);
            varBoolean  : if Value then Result := 'True' else Result := 'False';
            varString   : Result := Value;
            else          Result := '';
        end;
    except
        on E : Exception do E:=nil;
    end;
end;
//-----------------------------------------------------------------------------+
function VarToStringF(Value: Variant; Digits:Integer=8):String;
begin
    Result:='';
    DecimalSeparator:='.';
    try
        case TVarData(Value).VType of
            varByte,
            varShortInt,
            varSmallInt,
            varInteger,
            varWord,
            varLongWord,
            varInt64    : Result := IntToStr(Value);
            varSingle,
            varDouble,
            varCurrency : Result := FloatToStrF(Value,ffFixed,20,Digits);
            varDate     : Result := FormatDateTime('yyyy.mm.dd hh:nn:ss', Value);
            varBoolean  : if Value then Result := 'True' else Result := 'False';
            varString   : Result := Value;
            else          Result := '';
        end;
    except
        on E : Exception do E:=nil;
    end;
end;
//-----------------------------------------------------------------------------+
function HaveDir(const fn:string; const create:boolean=true):boolean;
var path:string;
begin
   path:=Copy(fn,1,Lastdelimiter('\',fn));
   result:=DirectoryExists(path);
   if not result then begin
      if(create)then begin
         Result:=ForceDirectories(path);
      end;
   end;
end;
//-----------------------------------------------------------------------------+
function GetLocalIP: String;
const WSVer = $101;
var
wsaData: TWSAData;
P: PHostEnt;
Buf: array [0..127] of Char;
begin
    Result := '';
    if WSAStartup(WSVer, wsaData) = 0 then begin
        if GetHostName(@Buf[0], 128) = 0 then begin
            P := GetHostByName(@Buf[0]);
            if P <> nil then Result := iNet_ntoa(PInAddr(p^.h_addr_list^)^);
        end;
        WSACleanup;
    end;
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var Data:array of Integer; SortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of Integer;
begin
    SetLength(arr,Length(data)*2);
    //---
    imin :=Length(data);
    imax :=Length(data);
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Integer));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Integer));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of Int64; sortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of int64;
begin
    SetLength(arr,Length(data)*2);
    for i:=0 to Length(arr)-1 do arr[i]:=0;
    //---
    imin :=Length(data);
    imax :=Length(data);
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Integer));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Integer));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of Double; sortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of Double;
begin
    SetLength(arr,Length(data)*2);
    for i:=0 to Length(arr)-1 do arr[i]:=0;
    //---
    imin :=Length(data);
    imax :=Length(data);
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Integer));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Integer));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of string; sortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of string;
begin
    SetLength(arr,Length(data)*2);
    for i:=0 to Length(arr)-1 do arr[i]:='';
    //---
    imin :=Length(data);
    imax :=Length(data);
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Integer));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Integer));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+
//| Рекурсивный квадратичный поиск в отсортированном масииве
//-----------------------------------------------------------------------------+
procedure FlipFlop(var data:array of Integer; val:Integer; var min,max:Integer);
var i:Integer;
begin
    i:=max-Trunc((max-min)/2);
    //--- flip
    while( val < data[i] )do begin
        max:=i;
        i:=Trunc(i/2);
        if( i < min )then Exit;
    end;
    min:=i;
    //--- flop
    while( val > data[i] )do begin
        min:=i;
        i:=i+Trunc((max-i)/2)+1;
        if( i > max )then Exit;     
    end;
    max:=i;
end;
//-----------------------------------------------------------------------------+
end.
