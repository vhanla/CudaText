(*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Copyright (c) Alexey Torgashin
*)
unit fix_focus_window;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef windows}
  Windows,
  simpleipc,
  {$endif}
  SysUtils,
  LCLIntf;

// Create SimpleIPC Server&Client to communicate with .lpr
{$ifdef windows}
var
  IPCClient : TSimpleIPCClient;
  IPCServer : TSimpleIPCServer;
{$ifend}

//WinAPI SetForegroundWindow function dont help on Win10
procedure DoFocusWindow(h: THandle);


implementation

{$ifdef windows}
type
  TSwitchFunc = procedure(h: HWND; fAltTab: BOOL); stdcall;

var
  SwitchFunc: TSwitchFunc = nil;

procedure DoFocusWindow(h: THandle);
begin
  if Assigned(SwitchFunc) then
  begin
    //2 ShowWindow calls are patch from https://github.com/Alexey-T/CudaText/issues/595
    //ShowWindow(h, SW_HIDE);
    //ShowWindow(h, SW_SHOW);
    
    //SwitchFunc(h, false); //Not needed anymore
  end
  else
    LCLIntf.SetForegroundWindow(h);
end;

var
  hLib: HINST;

initialization
  hLib:= LoadLibrary('user32.dll');
  Pointer(SwitchFunc):= GetProcAddress(hLib, 'SwitchToThisWindow');

{$else}
procedure DoFocusWindow(h: THandle);
begin
  LCLIntf.SetForegroundWindow(h);
end;
{$endif}

end.

