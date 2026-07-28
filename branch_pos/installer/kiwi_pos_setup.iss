; Kiwi Fresh POS - Inno Setup Script
; Requires Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
; Build: flutter build windows --release
; Then compile this script with Inno Setup Compiler

#define MyAppName "Kiwi-pos"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Kiwi Technologies"
#define MyAppURL "https://kiwi.store"
#define MyAppExeName "branch_pos.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/support
AppUpdatesURL={#MyAppURL}/updates
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=.\output
OutputBaseFilename=KiwiPOS_Setup_{#MyAppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
InternalCompressLevel=ultra64
WizardStyle=modern
WizardSizePercent=120
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
PrivilegesRequired=admin
DisableProgramGroupPage=auto
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "إنشاء اختصار في شريط التشغيل السريع"; GroupDescription: "اختصارات إضافية:"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\windows\runner\resources\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
Name: "{app}\data"; Permissions: users-full

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent shellexec

[Registry]
; Add to Windows PATH for command line access
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
    ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; \
    Flags: uninsdeletevalue; Check: Not IsAdminLoggedOn
; Register uninstall info
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}"; \
    ValueType: string; ValueName: "DisplayName"; ValueData: "{#MyAppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}"; \
    ValueType: string; ValueName: "DisplayVersion"; ValueData: "{#MyAppVersion}"

[Code]
// ──────────────────────────────────────────────────────────
// Check if app is running before install
// ──────────────────────────────────────────────────────────
function InitializeSetup: Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  // Try to gracefully close running instance
  if ShellExec('open', 'taskkill', '/f /im branch_pos.exe', '', SW_HIDE, ewNoWait, ResultCode) then
  begin
    Sleep(500); // Wait for process to terminate
  end;
end;

// ──────────────────────────────────────────────────────────
// Post-install: create data directory + apply permissions
// ──────────────────────────────────────────────────────────
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    ForceDirectories(ExpandConstant('{app}\data'));
    ForceDirectories(ExpandConstant('{app}\data\db'));
    ForceDirectories(ExpandConstant('{app}\data\logs'));
    ForceDirectories(ExpandConstant('{app}\data\exports'));
  end;
end;

// ──────────────────────────────────────────────────────────
// Uninstall cleanup
// ──────────────────────────────────────────────────────────
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // Remove user data if user confirms
    if MsgBox('هل تريد حذف جميع بيانات التطبيق؟', mbConfirmation, MB_YESNO) = IDYES then
    begin
      DelTree(ExpandConstant('{app}\data'), True, True, True);
    end;
  end;
end;
