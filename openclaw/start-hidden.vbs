Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "wsl.exe -e bash -c ""exec sleep infinity""", 0, False
