program cudatext;

{$mode objfpc}{$H+}

uses
  //heaptrc,
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, uniqueinstance_package, FormMain, FormConsole, proc_str,
  proc_py, proc_py_const, proc_globdata, FormFrame, form_menu_commands,
  formgoto, proc_cmd, form_menu_list, formsavetabs, formconfirmrep,
  formlexerprop, formlexerlib, proc_msg, proc_install_zip, formcolorsetup,
  formabout, formkeys, formlexerstylesload, formcharmaps, proc_keysdialog,
  proc_customdialog, proc_miscutils, ATLinkLabel, formlexerstyle,
  formlexerstylemap, formkeyinput, proc_scrollbars, proc_keymap_undolist,
  proc_customdialog_dummy, form_addon_report
  {$IFDEF WINDOWS}
  ,Windows, SimpleIPC, SysUtils, JsonConf, UniqueInstanceBase, Classes
  {$IFEND};

{$R *.res}
{$IFDEF WINDOWS}
type
  TSwitchFunc = procedure(h: HWND; fAltTab: BOOL); stdcall;

  { ServerHandler }

  TServerHandler = class(TComponent)
  private
    procedure ReceivedMessage(Sender: TObject);
  end;

var
  SwitchFunc: TSwitchFunc = nil;
  hLib: HINST;
  OneInstance : Boolean = False;
  IPCClient: TSimpleIPCClient;
  FIdentifier: String;

  IPCServer: TSimpleIPCServer;

  ServerHandler: TServerHandler;
  AlreadyRunning: Boolean = False;

procedure LoadBasicSettings(const fn: string);
var
  c: TJSONConfig;

begin
  c := TJSONConfig.Create(nil);
  try
    try
      c.Filename := fn;
    except
      on E: Exception do
      begin
        MsgBox(msgStatusErrorInConfigFile+#13+fn+#13#13+E.Message, MB_OK or MB_ICONERROR);
        Exit;
      end;
    end;
    OneInstance := c.GetValue('ui_one_instance', False);
  finally
    c.Free;
  end;
end;

{ ServerHandler }

// This will receive message from already running windowed cuda text
procedure TServerHandler.ReceivedMessage(Sender: TObject);
var
  CudaWnd: String;
begin
  CudaWnd := IPCServer.StringMessage;
  if CudaWnd <> 'NOCUDAWND' then
  begin
    IPCClient := TSimpleIPCClient.Create(nil);
    IPCClient.ServerId := GetServerId('cudatext.0');
    if IPCClient.ServerRunning then
    begin
      IPCClient.Active := True;
      IPCClient.SendStringMessage(ParamCount, GetFormattedParams);
    end;
    hLib:= LoadLibrary('user32.dll');
    try
      Pointer(SwitchFunc):= GetProcAddress(hLib, 'SwitchToThisWindow');
    finally
      FreeLibrary(hLib);
    end;
    if Assigned(SwitchFunc) then
       SwitchFunc(StrToInt(CudaWnd), False);
    IPCClient.Free;
  end;
end;

{$IFEND}
begin
  {$IFDEF WINDOWS}
  LoadBasicSettings(GetAppPath(cFileOptionsUser));
  if OneInstance then
  begin
    ServerHandler := TServerHandler.Create(nil);

    // start our server to listen existing cudatext's window handle
    IPCServer := TSimpleIPCServer.Create(nil);
    IPCServer.ServerID:='cudatext.1';
    IPCServer.Global:=True;
    IPCServer.OnMessage:=@ServerHandler.ReceivedMessage;
    IPCServer.StartServer;

    // find out if already running another cudatext's instance
    FIdentifier:='cudatext.0';
    IPCClient := TSimpleIPCClient.Create(nil);
    IPCClient.ServerId := GetServerId(FIdentifier);
    if IPCClient.ServerRunning then
    begin
      AlreadyRunning:=True;
      IPCClient.Free;

      // send pseudo command to ask for running cudatext's window instance
      IPCClient := TSimpleIPCClient.Create(nil);
      IPCClient.ServerID:='cudatext.2';
      if IPCClient.ServerRunning then
      begin

        IPCClient.Active:=True;
        IPCClient.SendStringMessage('NOCUDAWND');
      end;

    end;

    IPCClient.Free;
    IPCServer.Free;
    ServerHandler.Free;

  end;
  // Terminate program before initializing another CudaText window instance
  if AlreadyRunning then Exit;
  {$IFEND}
  Application.Title:='CudaText';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.

