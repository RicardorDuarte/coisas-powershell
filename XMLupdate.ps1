[xml]$ConfigFile = Get-Content "C:\Scripts\targets.xml" -Raw

$Machines = $ConfigFile.Targets.Machine

$Cred = Get-Credential

Invoke-Command -ComputerName ($Machines | ForEach-Object { $_.IP }) -Credential $Cred -ScriptBlock {
    Write-Output "a atualizar"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Install-Module -Name PSWindowsUpdate -Force
    Import-Module PSWindowsupdate -Force
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot
}