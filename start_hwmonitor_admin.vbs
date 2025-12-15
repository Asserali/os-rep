Set objShell = CreateObject("Shell.Application")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get script directory
strScriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
strPythonScript = strScriptPath & "\hwmonitor_service.py"

' Run Python script with admin rights
objShell.ShellExecute "python", """" & strPythonScript & """", strScriptPath, "runas", 0
