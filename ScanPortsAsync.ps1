###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  ScanNetworkAsync.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Asynchronus Port Scanner
# Repository   :  https://github.com/BornToBeRoot/PowerShell-Async-PortScanner
###############################################################################################################

<#
    .SYNOPSIS
    
    .DESCRIPTION

    .EXAMPLE

    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-Async-PortScanner
#>

[CmdletBinding()]
Param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        HeldMessage='Enter IP-Address of the device which you want to scan')]
    [IPAddress]$IPv4Address,

    [Parameter(
        Position=1,
        Mandatory=$false,
        HelpMessage='')]
    [Int32]$StartPort=1,

    [Parameter(
        Position=2,
        Mandatory=$false,
        HelpMessage='Enter the Start Port')]
    [Int32]$EndPort=65535
)

Begin{
    # Time when the script starts
    $StartTime = Get-Date

    # Script FileName
    $ScriptFileName = $MyInvocation.MyCommand.Name

    # Validate Port-Range
    if($StartPort -gt $EndPort)
    {
        Write-Host "Check your input! Invalid Port-Range (-StartPort can't be lower than -EndPort)" -ForegroundColor Red
        exit
    }
    
    # Some User-Output about the selected or default settings
        
}

Process{
    

}


End{


}