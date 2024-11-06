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
procedure ArrSort(var data:array of Integer);overload;
procedure ArrSort(var data:array of Int64);overload;
procedure ArrSort(var data:array of Double);overload;
procedure ArrSort(var data:array of string);overload;
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
procedure ArrSort(var data:array of Integer);overload;
var i,j:Integer;
arr:array of Integer;
imax,imin,imid:Int64;
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
                imid:=Trunc((imin+imax)/2)+1;
                if( data[i] < arr[imid] )then begin
                    for j:=imin to imid do begin
                        if( data[i] >= arr[j] )then begin
                            arr[j-1]:=arr[j];
                        end else begin
                            Dec(imin);
                            arr[j-1]:=data[i];
                            Break;
                        end;
                    end;
                end else begin
                    for j:=imax downto imid do begin
                        if( data[i] < arr[j] )then begin
                            arr[j+1]:=arr[j];
                        end else begin
                            inc(imax);
                            arr[j+1]:=data[i];
                            Break;
                        end;
                    end;
                end;
            end;
        end;
    end;
    //---
    for i:=0 to Length(data)-1 do data[i]:=arr[i+imin];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of Int64);overload;
var i,j:Integer;
arr:array of Int64;
imax,imin,imid:Int64;
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
                imid:=Trunc((imin+imax)/2)+1;
                if( data[i] < arr[imid] )then begin
                    for j:=imin to imid do begin
                        if( data[i] >= arr[j] )then begin
                            arr[j-1]:=arr[j];
                        end else begin
                            Dec(imin);
                            arr[j-1]:=data[i];
                            Break;
                        end;
                    end;
                end else begin
                    for j:=imax downto imid do begin
                        if( data[i] < arr[j] )then begin
                            arr[j+1]:=arr[j];
                        end else begin
                            inc(imax);
                            arr[j+1]:=data[i];
                            Break;
                        end;
                    end;
                end;
            end;
        end;
    end;
    //---
    for i:=0 to Length(data)-1 do data[i]:=arr[i+imin];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of Double);overload;
var i,j:Integer;
arr:array of Double;
imax,imin,imid:Int64;
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
                imid:=Trunc((imin+imax)/2)+1;
                if( data[i] < arr[imid] )then begin
                    for j:=imin to imid do begin
                        if( data[i] >= arr[j] )then begin
                            arr[j-1]:=arr[j];
                        end else begin
                            Dec(imin);
                            arr[j-1]:=data[i];
                            Break;
                        end;
                    end;
                end else begin
                    for j:=imax downto imid do begin
                        if( data[i] < arr[j] )then begin
                            arr[j+1]:=arr[j];
                        end else begin
                            inc(imax);
                            arr[j+1]:=data[i];
                            Break;
                        end;
                    end;
                end;
            end;
        end;
    end;
    //---
    for i:=0 to Length(data)-1 do data[i]:=arr[i+imin];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of string);overload;
var i,j:Integer;
arr:array of string;
imax,imin,imid:Int64;
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
                imid:=Trunc((imin+imax)/2)+1;
                if( data[i] < arr[imid] )then begin
                    for j:=imin to imid do begin
                        if( data[i] >= arr[j] )then begin
                            arr[j-1]:=arr[j];
                        end else begin
                            Dec(imin);
                            arr[j-1]:=data[i];
                            Break;
                        end;
                    end;
                end else begin
                    for j:=imax downto imid do begin
                        if( data[i] < arr[j] )then begin
                            arr[j+1]:=arr[j];
                        end else begin
                            inc(imax);
                            arr[j+1]:=data[i];
                            Break;
                        end;
                    end;
                end;
            end;
        end;
    end;
    //---
    for i:=0 to Length(data)-1 do data[i]:=arr[i+imin];
end;
//-----------------------------------------------------------------------------+
//| Рекурсивный квадратичный поиск в отсортированном масииве (почему то очень медленный по сравнению с обычным перебором)
//-----------------------------------------------------------------------------+
procedure FlipFlop(data:array of Integer; val:Integer; var min,max:Integer);
var ind:Integer;
begin
    ind:=max-Trunc((max-min)/2);
    //--- flip
    while( val < data[ind] )do begin
        max:=ind;
        ind:=Trunc(ind/2);
        if( ind < min )then Exit;
    end;
    min:=ind;
    //--- flop
    while( val > data[ind] )do begin
        min:=ind;
        ind:=ind+Trunc((max-ind)/2)+1;
        if( ind > max )then Exit;
    end;
    max:=ind;
end;
//-----------------------------------------------------------------------------+
end.
