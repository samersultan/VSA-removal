# Stop and disable the VSAX service
Stop-Service -Name "VSAX"
Set-Service -Name "VSAX" -StartupType Disabled

# Kill all instances of pcmontask.exe and pcmonitorsrv.exe
$pcmontaskPIDs = Get-Process -Name "pcmontask" | Select-Object -ExpandProperty Id
if ($pcmontaskPIDs) {
    Stop-Process -Id $pcmontaskPIDs -Force
}
$pcmonitorsrvPIDs = Get-Process -Name "pcmonitorsrv" | Select-Object -ExpandProperty Id
if ($pcmonitorsrvPIDs) {
    Stop-Process -Id $pcmonitorsrvPIDs -Force
}

# Uninstall VSA X using Windows Installer and remove registry keys
$result = Get-WmiObject Win32_Product -Filter "Name LIKE 'VSA X'" | Select IdentifyingNumber
$a = $result.IdentifyingNumber
msiexec.exe /X $a /qn
Remove-Item -Path "HKLM:\SOFTWARE\Kaseya\PC Monitor" -Recurse -Force
Write-Host "Uninstallation completed successfully"

# Delete scheduled task named VSA XServiceCheck
$TaskToDelete = "VSA XServiceCheck"

# create Task Scheduler COM object
$TS = New-Object -ComObject Schedule.Service

# connect to local task scheduler
$TS.Connect($env:COMPUTERNAME)

# get tasks folder (in this case, the root of Task Scheduler Library)
$TaskFolder = $TS.GetFolder("")

# get tasks in folder
$Tasks = $TaskFolder.GetTasks(1)

# step through all tasks in the folder
foreach ($Task in $Tasks) {
    if ($Task.Name -eq $TaskToDelete) {
        Write-Host ("Task " + $Task.Name + " will be removed")
        $TaskFolder.DeleteTask($Task.Name, 0)
    }
}
