###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  New-IPv4PortScan.ps1 
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Powerful asynchronus IPv4 Port Scanner
# Repository   :  https://github.com/BornToBeRoot/PowerShell_IPv4PortScanner
###############################################################################################################

<#
    .SYNOPSIS
    Powerful asynchronus IPv4 Port Scanner

    .DESCRIPTION

    .EXAMPLE

    .EXAMPLE
    
    .LINK
    https://github.com/BornToBeRoot/PowerShell_IPv4PortScanner
#>

[CmdletBinding()]
param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        HelpMessage='ComputerName or IPv4-Address of the device which you want to scan')]
    [String]$ComputerName,

    [Parameter(
        Position=1,
        HelpMessage='First port which should be scanned (Default=1)')]
    [Int32]$StartPort=1,

    [Parameter(
        Position=2,
        HelpMessage='Last port which should be scanned (Default=65535)')]
    [Int32]$EndPort=65535,

    [Parameter(
        Position=3,
        HelpMessage='Maximum number of threads at the same time (Default=100)')]
    [Int32]$Threads=100,

    [Parameter(
        Position=4,
        HelpMessage='Execute script without user interaction')]
    [switch]$Force,

    [Parameter(
        Position=5,
        HelpMessage='Update Service Name and Transport Protocol Port Number Registry from IANA.org')]
    [switch]$UpdateList
)

Begin{
    Write-Verbose "Script started at $(Get-Date)"

    # IANA --> Service Name and Transport Protocol Port Number Registry -> xml-file
    $IANA_PortList_WebUri = "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml"

    # Port list path
    $XML_PortList_Path = "$PSScriptRoot\IANA_ServiceName_and_TransportProtocolPortNumber_Registry.xml"
    $XML_PortList_BackupPath = "$PSScriptRoot\IANA_ServiceName_and_TransportProtocolPortNumber_Registry.xml.bak"

    # Function to update the list from IANA (Port list)
    function UpdateListFromIANA
    {
        try{
            Write-Verbose "Create backup of the IANA Service Name and Transport Protocol Port Number Registry..."

            # Backup file, before donload a new version
            if([System.IO.File]::Exists($XML_PortList_Path))
            {
                Rename-Item -Path $XML_PortList_Path -NewName $XML_PortList_BackupPath
            }

            Write-Verbose "Updating Service Name and Transport Protocol Port Number Registry from IANA.org..."

            # Download xml-file from IANA and save it
            [xml]$New_XML_PortList = Invoke-WebRequest -Uri $IANA_PortList_WebUri -ErrorAction Stop

            $New_XML_PortList.Save($XML_PortList_Path)

            # Remove backup, if no error
            if([System.IO.File]::Exists($XML_PortList_BackupPath))
            {
                Remove-Item -Path $XML_PortList_BackupPath
            }
        }
        catch{
            Write-Verbose "Cleanup downloaded file and restore backup..."

            # On error: cleanup downloaded file and restore backup
            if([System.IO.File]::Exists($XML_PortList_Path))
            {
                Remove-Item -Path $XML_PortList_Path -Force
            }

            if([System.IO.File]::Exists($XML_PortList_BackupPath))
            {
                Rename-Item -Path $XML_PortList_BackupPath -NewName $XML_PortList_Path
            }
        }
    } 
}

Process{
    if($UpdateList.IsPresent)
    {
        UpdateListFromIANA
    }
    elseif(-Not([System.IO.File]::Exists($XML_PortList_Path)))
    {
        Write-Host 'No xml-file to assign service with port found! Use the parameter "-UpdateList" to download the latest version from IANA.org. This warning doesn`t affect the scanning procedure.'
    }

    if([System.IO.File]::Exists($XML_PortList_Path))
    {
        $AssignServiceWithPort = $true
    }
    else 
    {
        $AssignServiceWithPort = $false    
    }
}

End{

}