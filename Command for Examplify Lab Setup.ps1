md "c:\Examplify"
xcopy /H /E /Y "\\spc-mdt01\1809DeploymentShare\Applications\_FDeploy+FDeepFreeze.Apps_\Examplify" "C:\Examplify"
cd "C:\Examplify"
C:\Examplify\Examplify_3.4.2_win.exe /s /v" /qn REBOOT=ReallySuppress" /z"C:\Examplify\simple-setup.json"
# Made by Ketchup
