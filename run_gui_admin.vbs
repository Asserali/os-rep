Set objShell = CreateObject("Shell.Application")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get the current directory
strCurrentDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Path to Python script
strPythonScript = strCurrentDir & "\monitor_gui.py"

' Run with admin rights
objShell.ShellExecute "python", """" & strPythonScript & """", strCurrentDir, "runas", 1
