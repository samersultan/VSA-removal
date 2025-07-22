#Requires -RunAsAdministrator

# Stop and disable the VSAX service
Try {
    Stop-Service -Name "VSAX" -ErrorAction Stop
    Set-Service -Name "VSAX" -StartupType Disabled
    Write-Host "VSAX service stopped and disabled."
} Catch {
    Write-Host "VSAX service not found or already stopped."
}

# Kill all instances of related processes
foreach ($proc in @("pcmontask", "pcmonitorsrv")) {
    Try {
        Get-Process -Name $proc -ErrorAction Stop | Stop-Process -Force
        Write-Host "$proc process stopped."
    } Catch {
        Write-Host "$proc process not running."
    }
}

# Uninstall VSA X using registry for reliability
$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
foreach ($keyPath in $uninstallKeys) {
    Get-ChildItem $keyPath | ForEach-Object {
        $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($props.DisplayName -like "VSA X*") {
            if ($props.UninstallString) {
                $uninstallString = $props.UninstallString
                if ($uninstallString -match "msiexec\.exe") {
                    $uninstallString = $uninstallString -replace "/I", "/X"
                    $uninstallString += " /qn"
                }
                Write-Host "Uninstalling: $($props.DisplayName)"
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c $uninstallString" -Wait
            }
        }
    }
}

# Remove leftover registry keys
Remove-Item -Path "HKLM:\SOFTWARE\Kaseya\PC Monitor" -Recurse -Force -ErrorAction SilentlyContinue

# Remove scheduled task
$TaskName = "VSA XServiceCheck"
Try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
    Write-Host "Scheduled task $TaskName removed."
} Catch {
    Write-Host "Scheduled task $TaskName not found."
}

# Remove VSA Manager desktop icon from Public Desktop (all users)
$publicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
$iconName = "VSA Manager.lnk"
$publicIconPath = Join-Path $publicDesktop $iconName

if (Test-Path $publicIconPath) {
    Remove-Item $publicIconPath -Force
    Write-Host "Removed VSA Manager desktop icon from all users (Public Desktop)."
} else {
    Write-Host "VSA Manager desktop icon not found on Public Desktop."
}

# Remove VSA Manager desktop icon from current user's desktop
$userDesktop = [Environment]::GetFolderPath("Desktop")
$userIconPath = Join-Path $userDesktop $iconName

if (Test-Path $userIconPath) {
    Remove-Item $userIconPath -Force
    Write-Host "Removed VSA Manager desktop icon from current user's desktop."
} else {
    Write-Host "VSA Manager desktop icon not found on current user's desktop."
}

Write-Host "Uninstallation completed successfully."
