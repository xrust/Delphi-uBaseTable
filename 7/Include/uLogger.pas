unit uLogger;
{//+-----------------------------------------------------------------+
    New Logger Class, try to make it fast an furios
}//+-----------------------------------------------------------------+
interface
//+------------------------------------------------------------------+
uses Windows, Messages, SysUtils, Variants, Classes, Controls, Forms, Dialogs, StdCtrls, SyncObjs, uCommon, uNixTime;
//+------------------------------------------------------------------+
type PMemo = ^TMemo;
//+------------------------------------------------------------------+
type TLogger = class(TThread)
    private
        FStop       : Boolean;
        FMemo       : TMemo;
        FText       : ShortString;
        FCapasity   : Word;
        FAppender   : ShortString;
        FFilePath   : string;
        FList       : TStringList;
        FCash       : TStringList;
        FAutoClear  : Boolean;
        FBusy       : Boolean;
        FSync       : TCriticalSection;
        //---
        procedure   MemoLineAdd;
        procedure   MemoLinesDel;
        function    IsStopped:Boolean;
    protected
        procedure   Execute;override;
    public
        destructor  Destroy;override;
        constructor Create(Memo:PMemo; FnAppender:ShortString='');
        procedure   Clear;
        procedure   JumpToEnd;
        function    GetLog(text:string=''):string;
        function    Print(text:string=''):string;overload;
        function    Print(Value: Variant):string;overload;
        function    PrintF(Const Formatting : string; Const Data : array of const):string;
        function    PrintLn(Const Data : array of Variant):string;
        property    ClearIfNewDay : Boolean read FAutoClear write FAutoClear default False;
        property    Capasity : Word read FCapasity write FCapasity default 0;
end;
//+------------------------------------------------------------------+
var CLog:TLogger;LogComp:TComponent=nil;IsLogInited:boolean=false;
//+------------------------------------------------------------------+
procedure   LogInit;
function    PrintLn(Const Data : array of Variant):string;
function    PrintF(Const Formatting : string; Const Data : array of const):string;
function    GetLog(text:string=''):string;overload;
function    GetLog(Value: Variant):string;overload;
function    PrintLog(text:string=''):string;overload;
function    PrintLog(Value: Variant):string;overload;
procedure   LogClear;
procedure   LogJumpToEnd;
procedure   LogSetCapasity(CountOfLines:Integer);
//+------------------------------------------------------------------+
implementation
//+------------------------------------------------------------------+
procedure LogInit;
var i,ii:Integer;
begin
    if( CLog <> nil )then Exit;
    //---
    LogComp:=nil;
    for i:=0 to Screen.FormCount -1 do begin
        for ii:= 0 to Screen.Forms[i].ComponentCount -1 do begin
            if(Screen.Forms[i].Components[ii].ClassType <> TMemo)then Continue;
            if(AnsiCompareStr('log',LowerCase(Screen.Forms[i].Components[ii].Name)) = 0)then begin
                LogComp:=Screen.Forms[i].Components[ii];
                Break;
            end;
        end;
    end;
    //---
    if( LogComp <> nil )then begin
        CLog:=TLogger.Create(@TMemo(LogComp));
    end else begin
        CLog:=TLogger.Create(nil);
    end;
end;
//+------------------------------------------------------------------+
function    PrintLn(Const Data : array of Variant):string;
begin
    if( LogComp = nil )then LogInit;
    if( CLog <> nil )then Result:=CLog.PrintLn(Data) else Result:='Error ! Clog Not Initialised!';
end;
//+------------------------------------------------------------------+
function    PrintF(Const Formatting : string; Const Data : array of const):string;
begin
    if( LogComp = nil )then LogInit;
    if( CLog <> nil )then Result:=CLog.PrintF(Formatting,Data) else Result:='Error ! Clog Not Initialised!';
end;
//+------------------------------------------------------------------+
function PrintLog(text:string=''):string;
begin
    if( LogComp = nil )then LogInit;
    if( CLog <> nil )then Result:=CLog.Print(text) else Result:='Error ! Clog Not Initialised!';
end;
//+------------------------------------------------------------------+
function PrintLog(Value: Variant):string;overload;
begin
    if( LogComp = nil )then LogInit;
    if( CLog <> nil )then Result:=CLog.Print(Value) else Result:='Error ! Clog Not Initialised!';
end;
//+------------------------------------------------------------------+
function GetLog(text:string=''):string;
begin
    if( LogComp = nil )then LogInit;
    if( CLog <> nil )then Result:=CLog.Print(text) else Result:='Error ! Clog Not Initialised!';
end;
//+------------------------------------------------------------------+
function GetLog(Value: Variant):string;overload;
begin
    if( LogComp = nil )then LogInit;
    if( CLog <> nil )then Result:=CLog.Print(Value) else Result:='Error ! Clog Not Initialised!';
end;
//+------------------------------------------------------------------+
procedure   LogJumpToEnd;begin if( LogComp = nil )then LogInit; if( CLog <> nil )then CLog.JumpToEnd;end;
//+------------------------------------------------------------------+
procedure   LogClear;begin if( LogComp = nil )then LogInit; if( CLog <> nil )then CLog.Clear;end;
//+------------------------------------------------------------------+
procedure   LogSetCapasity(CountOfLines:Integer);
begin
    if( LogComp = nil )then LogInit; if( CLog <> nil )then CLog.Capasity:=CountOfLines;
end;
//+------------------------------------------------------------------+
destructor  TLogger.Destroy;
begin
    FStop:=True;
    FCash.Free;
    FList.Free;
    FSync.Free;
    inherited;
end;
//+------------------------------------------------------------------+
constructor TLogger.Create(Memo:PMemo; FnAppender:ShortString='');var fn:string;
begin
    FMemo:=nil;
    FText:='';
    FFilePath:='';
    FAppender:=FnAppender;
    FBusy:=False;
    FCash:=TStringList.Create;
    FList:=TStringList.Create;
    FSync:=TCriticalSection.Create;
    //--- formatting log file name and create file folder
    fn:=ExtractFileName(Application.ExeName);
    Delete(fn,Pos('.',fn),100);
    FFilePath:=extractfilepath(paramstr(0))+fn+'\';
    HaveDir(FFilePath,True);                                                                        
    //---
    if( Memo <> nil )then FMemo:=Memo^;
    //---
    FStop:=False;
    inherited Create(False);
    Self.Priority:=tpNormal;
    Self.FreeOnTerminate:=False;
end;
//+------------------------------------------------------------------+
procedure   TLogger.Clear;begin if( FMemo <> nil )then FMemo.Clear;end;
//+------------------------------------------------------------------+
procedure   TLogger.JumpToEnd;
begin
    if( FMemo <> nil )then begin
        FMemo.Lines.Add('');
        FMemo.Lines.Delete(FMemo.Lines.Count-1);
    end;
end;
//+------------------------------------------------------------------+
function    TLogger.GetLog(text:string=''):string;begin Result:=Print(text);end;
//+------------------------------------------------------------------+
function    TLogger.Print(Value: Variant):string;
var i:Integer;
begin
    Result:=CurrTimeToStr+' | '+VarToString(Value);
    FCash.Add(Result);
    if( not FBusy )then begin
        FSync.Enter;
        for i:=0 to FCash.Count-1 do FList.Add(FCash[i]);
        FSync.Leave;
        FCash.Clear;
    end;
end;
//+------------------------------------------------------------------+
function    TLogger.Print(text:string=''):string;
var i:Integer;
begin
    Result:=CurrTimeToStr+' | '+text;
    FCash.Add(Result);
    if( not FBusy )then begin
        FSync.Enter;
        for i:=0 to FCash.Count-1 do FList.Add(FCash[i]);
        FSync.Leave;
        FCash.Clear;
    end;
end;
//+------------------------------------------------------------------+
function    TLogger.PrintLn(Const Data : array of Variant):string;
var i:Integer;text:string;
begin
    DecimalSeparator:='.';
    for i:=0 to Length(Data)-1 do text:=text+VarToString(Data[i]);
    Result:=Print(text);
end;
//+------------------------------------------------------------------+
function    TLogger.PrintF(Const Formatting : string; Const Data : array of const):string;begin DecimalSeparator:='.';Result:=Print(Format(Formatting,Data));end;
//+------------------------------------------------------------------+
procedure   TLogger.MemoLineAdd;begin if( FText <> '' )then FMemo.Lines.Add(FText);FText:='';end;
//+------------------------------------------------------------------+
procedure   TLogger.MemoLinesDel;begin while( FMemo.Lines.Count > FCapasity )do FMemo.Lines.Delete(0);end;
//+------------------------------------------------------------------+
function    TLogger.IsStopped:Boolean;begin
    Result:=True;
    if( Terminated )or( Application.Terminated )or( FStop )then Exit;
    Result:=False;
end;
//+------------------------------------------------------------------+
procedure   TLogger.Execute;var list:TStringList;
var i:Integer; fhd:TextFile;path:string;
begin
    list:=TStringList.Create;
    while(not IsStopped )do begin
        if( FList.Count > 0 )then begin
            FBusy:=True;
            FSync.Enter;
            list.Assign(FList);
            FList.Clear;
            FSync.Leave;
        end else begin
            Sleep(1);
            Continue;
        end;
        FBusy:=False;
        //---
        try
            if( FMemo <> nil )then begin
                for i:=0 to list.Count-1 do begin
                    FText:=list[i];
                    Synchronize(MemoLineAdd);
                end;
                if( FCapasity > 0 )then Synchronize(MemoLinesDel);
            end;
        except
            on E : Exception do begin
                list.Add('TMemo Writing ERROR : '+E.ClassName+' : '+E.Message);
                E:=nil;
            end;
        end;
        //---
        try
            path:=FFilePath+FormatDateTime('yyyymmdd',Now)+FAppender+'.log';
            AssignFile(fhd,path);
            if(not FileExists(path))then begin
                ReWrite(fhd);
                if( FAutoClear )then Clear;
            end else begin
                Append(fhd);
            end;
            for i:=0 to list.Count-1 do WriteLn(fhd,list[i]);
            CloseFile(fhd);
        except
            on E : Exception do begin
                FText:=('Log File Writing ERROR : '+E.ClassName+' : '+E.Message);
                Synchronize(MemoLineAdd);
                E:=nil;
            end;
        end;
        //---
        list.Clear;
        //---
        Sleep(1);
    end;
    list.Free;
end;
//+------------------------------------------------------------------+
end.
