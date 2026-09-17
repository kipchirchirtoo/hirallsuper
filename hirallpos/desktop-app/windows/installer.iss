[Setup]
AppName=Giftmart Supermarket POS
AppVersion=2.0.0
DefaultDirName={autopf}\Giftmart POS
DefaultGroupName=Giftmart POS
OutputDir=..\..\..\
OutputBaseFilename=hirall-pos-windows-setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=runner\resources\app_icon.ico

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Giftmart POS"; Filename: "{app}\hirall_pos.exe"
Name: "{autodesktop}\Giftmart POS"; Filename: "{app}\hirall_pos.exe"

[Run]
Filename: "{app}\hirall_pos.exe"; Description: "Launch Giftmart POS"; Flags: postinstall nowait skipifsilent
