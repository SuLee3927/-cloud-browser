' Run home-bridge.cmd silently in the background (no console window).
' Usage: keep this file next to home-bridge.cmd;
'        for auto-start, put a shortcut of this file into shell:startup.
Dim fso, here, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
here = fso.GetParentFolderName(WScript.ScriptFullName)
cmd = "cmd /c """ & here & "\home-bridge.cmd"""
CreateObject("WScript.Shell").Run cmd, 0, False
