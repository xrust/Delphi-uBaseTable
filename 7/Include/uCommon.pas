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
                '0'..'9': ; // צטפנû
                #8: ; // חאבמי
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

//-----------------------------------------------------------------------------+

//-----------------------------------------------------------------------------+

//-----------------------------------------------------------------------------+

//-----------------------------------------------------------------------------+
end.
