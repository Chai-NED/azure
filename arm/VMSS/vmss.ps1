New-Item -ItemType Directory c:\temp -Verbose

Invoke-WebRequest https://download.microsoft.com/download/8/D/A/8DA04DA7-565B-4372-BBCE-D44C7809A467/dotnet-runtime-2.0.6-win-x64.exe -outfile c:\temp\dotnet-runtime-2.0.6-win-x64.exe -Verbose

Start-Process c:\temp\dotnet-runtime-2.0.6-win-x64.exe -ArgumentList '/quiet /norestart /log c:\temp\netcoreinstalllog.txt' -Wait -Verbose
