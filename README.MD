# VSA X RMM Uninstall Script

This PowerShell script completely removes the VSA X RMM agent from Windows computers.  
It will:

- Stop and disable the VSAX service
- Kill any running VSA X processes
- Uninstall VSA X using its uninstaller
- Remove leftover registry keys
- Delete the "VSA XServiceCheck" scheduled task

## Usage

Run the script as an administrator:

```powershell
.\uninstall-vsa-x.ps1
