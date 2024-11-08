unit uCommon;
{//----------------------------------------------------------------------------+
    Set Of Common Functions    
}//----------------------------------------------------------------------------+
interface
//-----------------------------------------------------------------------------+
uses Windows, Messages, SysUtils, Variants, Classes, Controls, Forms, StdCtrls, ExtCtrls, WinSock, Mask;
//-----------------------------------------------------------------------------+
const INT_MAX = 2147483647;
const INT_MIN = -2147483647;
const UINT_MAX = 4294967295;
const INT64_MAX = 9223372036854775807;
const INT64_MIN = -9223372036854775807;
//-----------------------------------------------------------------------------+
type TTypeOfVars = (tvString,tvUint,tvInt,tvDouble,tvIpAddr,tvDate,tvTime,tvDateTime);
//-----------------------------------------------------------------------------+
procedure CheckKeyPress(TypeVar:TTypeOfVars; WinComp:TComponent; var Key: Char);
//-----------------------------------------------------------------------------+
function  HaveDir(const fn:string; const create:boolean=true):boolean;
function  GetLocalIP: String;
function  IntToStr64(Value: Int64): string;
function  VarToString(Value: Variant):String;overload;
function  VarToStringF(Value: Variant; Digits:Integer=8):String;overload
procedure ArrSort(var data:array of Integer; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var data:array of Int64; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var data:array of Double; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var data:array of ShortString; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var data:array of AnsiString; sortByDecrement:Boolean=False);overload;
//-----------------------------------------------------------------------------+
function iInc(val:Byte;i:Byte=1):Byte;overload;
function iInc(val:ShortInt;i:Byte=1):ShortInt;overload;
function iInc(val:Word;i:Word=1):Word;overload;
function iInc(val:LongWord;i:LongWord=1):LongWord;overload;
function iInc(val:Integer;i:Integer=1):Integer;overload;
function iInc(val:Int64;i:Int64=1):Int64;overload;
function iDec(val:Byte;i:Byte=1):Byte;overload;
function iDec(val:ShortInt;i:Byte=1):ShortInt;overload;
function iDec(val:Word;i:Word=1):Word;overload;
function iDec(val:LongWord;i:LongWord=1):LongWord;overload;
function iDec(val:Integer;i:Integer=1):Integer;overload;
function iDec(val:Int64;i:Int64=1):Int64;overload;
//-----------------------------------------------------------------------------+
implementation
//-----------------------------------------------------------------------------+
function iInc(val:Byte;i:Byte=1):Byte;overload;begin inc(val,i);Result:=val;end;
function iInc(val:ShortInt;i:Byte=1):ShortInt;overload;begin inc(val,i);Result:=val;end;
function iInc(val:Word;i:Word=1):Word;overload;begin inc(val,i);Result:=val;end;
function iInc(val:LongWord;i:LongWord=1):LongWord;overload;begin inc(val,i);Result:=val;end;
function iInc(val:Integer;i:Integer=1):Integer;overload;begin inc(val,i);Result:=val;end;
function iInc(val:Int64;i:Int64=1):Int64;overload;begin inc(val,i);Result:=val;end;
//-----------------------------------------------------------------------------+
function iDec(val:Byte;i:Byte=1):Byte;overload;begin Dec(val,i);Result:=val;end;
function iDec(val:ShortInt;i:Byte=1):ShortInt;overload;begin Dec(val,i);Result:=val;end;
function iDec(val:Word;i:Word=1):Word;overload;begin Dec(val,i);Result:=val;end;
function iDec(val:LongWord;i:LongWord=1):LongWord;overload;begin Dec(val,i);Result:=val;end;
function iDec(val:Integer;i:Integer=1):Integer;overload;begin Dec(val,i);Result:=val;end;
function iDec(val:Int64;i:Int64=1):Int64;overload;begin Dec(val,i);Result:=val;end;
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
procedure CvtInt64;
asm
        OR      CL, CL
        JNZ     @start             // CL = 0  => signed integer conversion
        MOV     ECX, 10
        TEST    [EAX + 4], $80000000
        JZ      @start
        PUSH    [EAX + 4]
        PUSH    [EAX]
        MOV     EAX, ESP
        NEG     [ESP]              // negate the value
        ADC     [ESP + 4],0
        NEG     [ESP + 4]
        CALL    @start             // perform unsigned conversion
        MOV     [ESI-1].Byte, '-'  // tack on the negative sign
        DEC     ESI
        INC     ECX
        ADD     ESP, 8
        RET

@start:   // perform unsigned conversion
        PUSH    ESI
        SUB     ESP, 4
        FNSTCW  [ESP+2].Word     // save
        FNSTCW  [ESP].Word       // scratch
        OR      [ESP].Word, $0F00  // trunc toward zero, full precision
        FLDCW   [ESP].Word

        MOV     [ESP].Word, CX
        FLD1
        TEST    [EAX + 4], $80000000 // test for negative
        JZ      @ld1                 // FPU doesn't understand unsigned ints
        PUSH    [EAX + 4]            // copy value before modifying
        PUSH    [EAX]
        AND     [ESP + 4], $7FFFFFFF // clear the sign bit
        PUSH    $7FFFFFFF
        PUSH    $FFFFFFFF
        FILD    [ESP + 8].QWord     // load value
        FILD    [ESP].QWord
        FADD    ST(0), ST(2)        // Add 1.  Produces unsigned $80000000 in ST(0)
        FADDP   ST(1), ST(0)        // Add $80000000 to value to replace the sign bit
        ADD     ESP, 16
        JMP     @ld2
@ld1:
        FILD    [EAX].QWord         // value
@ld2:
        FILD    [ESP].Word          // base
        FLD     ST(1)
@loop:
        DEC     ESI
        FPREM                       // accumulator mod base
        FISTP   [ESP].Word
        FDIV    ST(1), ST(0)        // accumulator := acumulator / base
        MOV     AL, [ESP].Byte      // overlap long FPU division op with int ops
        ADD     AL, '0'
        CMP     AL, '0'+10
        JB      @store
        ADD     AL, ('A'-'0')-10
@store:
        MOV     [ESI].Byte, AL
        FLD     ST(1)           // copy accumulator
        FCOM    ST(3)           // if accumulator >= 1.0 then loop
        FSTSW   AX
        SAHF
        JAE @loop

        FLDCW   [ESP+2].Word
        ADD     ESP,4

        FFREE   ST(3)
        FFREE   ST(2)
        FFREE   ST(1);
        FFREE   ST(0);

        POP     ECX             // original ESI
        SUB     ECX, ESI        // ECX = length of converted string
        SUB     EDX,ECX
        JBE     @done           // output longer than field width = no pad
        SUB     ESI,EDX
        MOV     AL,'0'
        ADD     ECX,EDX
        JMP     @z
@zloop: MOV     [ESI+EDX].Byte,AL
@z:     DEC     EDX
        JNZ     @zloop
        MOV     [ESI].Byte,AL
@done:
end;
//-----------------------------------------------------------------------------+
function IntToStr64(Value: Int64): string;
asm
        PUSH    ESI
        MOV     ESI, ESP
        SUB     ESP, 32        // 32 chars
        XOR     ECX, ECX       // base 10 signed
        PUSH    EAX            // result ptr
        XOR     EDX, EDX       // zero filled field width: 0 for no leading zeros
        LEA     EAX, Value;
        CALL    CvtInt64

        MOV     EDX, ESI
        POP     EAX            // result ptr
        CALL    System.@LStrFromPCharLen
        ADD     ESP, 32
        POP     ESI
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
            varLongWord : Result := IntToStr(Value);
            varInt64    : Result := IntToStr64(Value);
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
            varLongWord : Result := IntToStr(Value);
            varInt64    : Result := IntToStr64(Value);
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
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Int64));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Int64));
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
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Double));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Double));
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
procedure ArrSort(var data:array of ShortString; sortByDecrement:Boolean=False);overload;
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
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(ShortString));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(ShortString));
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
procedure ArrSort(var data:array of AnsiString; sortByDecrement:Boolean=False);overload;
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
                    for j:=imin to imid do arr[j-1]:=arr[j];
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    for j:=imax downto imid+1 do arr[j+1]:=arr[j];
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
