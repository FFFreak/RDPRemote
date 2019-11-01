<# RDPRemote.ps1 #>
<#
  LanSweeper Action - RDP Shadow Lan Sweeper Test
  Based on personal boredom and Internet sources.

  LSAction:
  powershell -exec bypass -Command "{actionpath}RDPRemote.ps1 -Computer "{smartname}" -LSPath '{actionpath}' "

#>


param(
    [string]$LSPath,
    [string]$Computer
    )

if (($LSPath.length + $computer.length) -eq 0) {
  write-host "No Inputs, script not called correctly - exiting..."
  sleep 5
  exit
}


###################
# Elevate Process #
###################
# https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/
# http://stackoverflow.com/questions/21559724/getting-all-named-parameters-from-powershell-including-empty-and-set-ones

$MyWindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$MyWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($MyWindowsIdentity)
$AdminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

#Check current process for Administrator Role
If (-Not $MyWindowsPrincipal.IsInRole($AdminRole) -and $Host.UI.RawUI.BackgroundColor -ne 'Black') {
<#  If ($Host.UI.RawUI.BackgroundColor -Eq 'Black') {
    Write-host "You did not arrive at an admin account - exiting to prompt"
    Write-host "DEBUG: Arrived here as: $($env:USERDOMAIN)\$($env:UserName)"
    exit
  }
#>
  If ($MyInvocation.Line -Match [RegEx]"$($MyInvocation.MyCommand.Name)['""]?(.*)") {$CommandLineAfterScriptFileSpec = $Matches[1]}
  $CommandLineAfterScriptFileSpec = $CommandLineAfterScriptFileSpec.Replace('""', '~~').Replace('"', '""""').Replace('~~', '""""""')
  $objProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
  $objProcess.Arguments = "-NoExit -exec bypass -Command &'$PSCommandPath'$CommandLineAfterScriptFileSpec"
  $objProcess.Verb = "RunAs"

  # Set Current User - Danny

  # Option to Change user in spawned process - Danny
  $newUser = $env:UserName
  write-host "NOTE: Will assume all usernames are in $($env:USERDOMAIN)"
  Write-host -nonewline "Run As user [$($env:USERDOMAIN)\$($env:UserName)]?  "
  $newUser = Read-host
  if ($newUser -ne $env:UserName -and $newUser.length -gt 0) {
    $PwDialogue = get-credential -Username $($env:USERDOMAIN + "\" + $newUser) -Message "Please Enter UserName / Password"
    $objProcess.Username = $PwDialogue.UserName.Split("\")[1]
    $objProcess.Domain = $PwDialogue.UserName.Split("\")[0]
    $objProcess.Password = $PwDialogue.Password
    $objProcess.WorkingDirectory = $LSPath
    $objProcess.UseShellExecute = $false
  }

  $objProcessHandle = [System.Diagnostics.Process]::Start($objProcess)
  write-host "Process Exit"
  sleep 5
  Exit
} ElseIf ($Host.UI.RawUI.BackgroundColor -Eq 'Black') {
  #Check for recursive call with elevated privilege by checking the background color to only change the environment on a new process.
  $Host.UI.RawUI.WindowTitle = "$PSCommandPath (Elevated)"
  $Host.UI.RawUI.BackgroundColor = "DarkBlue"
  Set-Location $PSScriptRoot
  Clear-Host
}
 
<# BASE CODE #>
write-host "LS Action Path: $LSPath"
write-host "User: $($env:USERDOMAIN)\$($env:UserName)`n`r"
write-host "Querying $($Computer)..."
Start-Process -FilePath "$($LSPath)query.exe" -NoNewWindow -wait -WorkingDirectory $LSPath -ArgumentList "session /server:$Computer"
Write-host ""
write-host " ** If Access Denied [q]"
Write-host -nonewline "Please Enter the session Number [1]: "
$SessionID = Read-host
if ($SessionID -eq 'q') {
  write-host "Quitting to prompt... Close Window any time"
  sleep 3
  exit
}
if ($SessionID -eq "" -or $SessionID -eq $null) { $SessionID = 1 }
Write-host ""
Write-host -nonewline "Do you want Remote Control [N]?"
$RemoteC = Read-host
if ($RemoteC -eq "" -or $RemoteC -eq $null) { $RemoteC = $true }
elseif ($RemoteC.toLower().length -eq 3 -and $RemoteC.toLower()[0] -eq 'y') {
  $RemoteC = $true} else { $RemoteC = $false }
if ($RemoteC) { mstsc /shadow:$SessionID /v $Computer /control }
else { mstsc /shadow:$SessionID /v $Computer }

write-host "Command Done!  Exiting to prompt."
exit
