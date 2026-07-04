[Setup]
AppName=Fresh Branch POS
AppVersion=1.0
DefaultDirName={autopf}\Fresh-Branch-POS
DefaultGroupName=Fresh Branch POS
OutputDir=C:\Users\IRAQ SOFT\Desktop
OutputBaseFilename=Fresh_Branch_POS_Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "C:\Users\IRAQ SOFT\Desktop\fresh-app\branch_pos\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\Fresh Branch POS"; Filename: "{app}\branch_pos.exe"
Name: "{group}\Fresh Branch POS"; Filename: "{app}\branch_pos.exe"

[Run]
Filename: "{app}\branch_pos.exe"; Description: "{cm:LaunchProgram,Fresh Branch POS}"; Flags: nowait postinstall skipifsilent
