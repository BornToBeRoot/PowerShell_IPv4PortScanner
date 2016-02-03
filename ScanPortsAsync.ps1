###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  ScanPortsAsync.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Asynchronus Port Scanner
# Repository   :  https://github.com/BornToBeRoot/PowerShell-Async-PortScanner
###############################################################################################################

<#
    .SYNOPSIS
    Powerful asynchronus Port-Scanner which returns a custom PowerShell-Object with basic informations about the 
    scanned Port-Range include Port and Status.
    
    .DESCRIPTION
    This is a powerful asynchronus Port-Scanner working with the PowerShell RunspacePool. You can scan any 
    Port-Range you want. 
    
    This script also work fine along with my asychronus IP-Scanner published on GitHub too. You can easily
    pipe the output of the IP-Scanner result in this script.
    If you found a bug or have some ideas to improve this script... Let me know. You find my Github profile in
    the links below.
    .EXAMPLE
    .\ScanPortsAsync.ps1 -IPv4Address 172.16.0.1 -StartPort 1 -EndPort 1000
    .EXAMPLE
    .\ScanPortsAsync.ps1 -IPv4Address 192.168.1.100 -IncludeClosed
    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-Async-PortScanner
#>

[CmdletBinding()]
Param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        HelpMessage='Enter IP-Address of the device which you want to scan')]
    [IPAddress]$IPv4Address,

    [Parameter(
        Position=1,
        Mandatory=$false,
        HelpMessage='Enter the Start-Port (Default=1)')]
    [Int32]$StartPort=1,

    [Parameter(
        Position=2,
        Mandatory=$false,
        HelpMessage='Enter the End-Port (Default=65535)')]
    [Int32]$EndPort=65535,

    [Parameter(
        Position=3,
        Mandatory=$false,
        HelpMessage='Set the maximum number of threads at the same time (Default=100)')]
    [Int32]$Threads=100,

    [Parameter(
        Position=4,
        Mandatory=$false,
        HelpMessage='Show closed Ports in result')]
    [Switch]$IncludeClosed
)

Begin{
    # Time when the script starts
    $StartTime = Get-Date

    # Script FileName
    $ScriptFileName = $MyInvocation.MyCommand.Name

    # Validate Port-Range
    if($StartPort -gt $EndPort)
    {
        Write-Host "Check your input! Invalid Port-Range... (-StartPort can't be lower than -EndPort)" -ForegroundColor Red 
        exit    
    }
    
    $PortRange = ($EndPort - $StartPort)

    if(-not( Test-Connection -ComputerName $IPv4Address -Count 2 -Quiet))
    {
        Write-Host "IP-Address not reachable!" -ForegroundColor Red
        exit
    }
    
    # Some User-Output about the selected or default settings
    Write-Host "`nScript ($ScriptFileName) started at $StartTime" -ForegroundColor Green
    Write-Host "`n+---------------------------------------Settings----------------------------------------`n|"
    Write-Host "| IP-Address:`t$IPv4Address"
    Write-Host "| Port-Range:`t$StartPort-$EndPort"
    Write-Host "| Threads:`t`t$Threads"
    Write-Host "|`n+---------------------------------------------------------------------------------------`n"         
}

Process{
    # Scriptblock that will run in runspaces (threads)...
    [System.Management.Automation.ScriptBlock]$ScriptBlock = {
        # Parameters
        $IPv4Address = $args[0]
        $Port = $args[1]
               
        try{                      
            $Socket = New-Object System.Net.Sockets.TcpClient($IPv4Address,$Port)
            
            if($Socket.Connected)
            {
                $Status = "Open"             
                $Socket.Close()
            }
        }
        catch
        {
            $Status = "Closed"
        }
    
        $Result = New-Object -TypeName PSObject
        Add-Member -InputObject $Result -MemberType NoteProperty -Name Port -Value $Port
        Add-Member -InputObject $Result -MemberType NoteProperty -Name Status -Value $Status
        return $Result    
    }
    
    # Setting up runspaces
    Write-Host "Setting up Runspace-Pool...`t`t" -ForegroundColor Yellow -NoNewline
    
    $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $Threads, $Host)
    $RunspacePool.Open()
    $Jobs = @()
 
    Write-Host "[" -ForegroundColor Gray -NoNewline; Write-Host "Done" -ForegroundColor Green -NoNewline; Write-Host "]" -ForegroundColor Gray	

    #Setting up jobs
    Write-Host "Setting up jobs...`t`t`t" -ForegroundColor Yellow -NoNewline

    foreach($Port in $StartPort..$EndPort)
    {
        if($PortRange -gt 0) { $Progress_Percent = (($Port - $StartPort) / $PortRange) * 100 } else { $Progress_Percent = 100 }
        Write-Progress -Activity "Setting up jobs..." -Id 1 -Status "Current Port: $Port"  -PercentComplete ($Progress_Percent)
        
        $Job = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock).AddArgument($IPv4Address).AddArgument($Port)
        $Job.RunspacePool = $RunspacePool
        $Jobs += New-Object psobject -Property @{
            RunNum = $Port - $StartPort
            Pipe = $Job
            Result = $Job.BeginInvoke()
        }
    }

    Write-Host "[" -ForegroundColor Gray -NoNewline; Write-Host "Done" -ForegroundColor Green -NoNewline; Write-Host "]" -ForegroundColor Gray	

    # Wait until all Jobs are finished
    Write-Host "Waiting for jobs to complete...`t`t" -ForegroundColor Yellow -NoNewline

    Do {
        Start-Sleep -Milliseconds 500

        Write-Progress -Activity "Waiting for jobs to complete... ($($Threads - $($RunspacePool.GetAvailableRunspaces())) of $Threads threads running)" -Id 1 -PercentComplete (($Jobs.Count - $($($Jobs | Where-Object {$_.Result.IsCompleted -eq $false}).Count)) / $Jobs.Count * 100) -Status "$(@($($Jobs | Where-Object {$_.Result.IsCompleted -eq $false})).Count) remaining..."
    } While ($Jobs.Result.IsCompleted -contains $false)
    
    Write-Host "[" -ForegroundColor Gray -NoNewline; Write-Host "Done" -ForegroundColor Green -NoNewline; Write-Host "]" -ForegroundColor Gray		
	
	Write-Host "Process results...`t`t`t" -ForegroundColor Yellow -NoNewline

    # Built global array  
    $Results = @()

    # Get results and fill the array
    foreach($Job in $Jobs)
    {
        $Results += $Job.Pipe.EndInvoke($Job.Result)
    }

    Write-Host "[" -ForegroundColor Gray -NoNewline; Write-Host "Done" -ForegroundColor Green -NoNewline; Write-Host "]" -ForegroundColor Gray	
}


End{    
    $EndTime = Get-Date
        
    $ExecutionTimeMinutes = (New-TimeSpan -Start $StartTime -End $EndTime).Minutes
    $ExecutionTimeSeconds = (New-TimeSpan -Start $StartTime -End $EndTime).Seconds
        
    # Some User-Output with Device UP/Down and execution time
    Write-Host "`n+----------------------------------------Result-----------------------------------------`n|"
    Write-Host "|  Ports Open:`t`t$(@($Results | Where-Object {($_.Status -eq "Open")}).Count)" 
    Write-Host "|  Ports Closed:`t$(@($Results | Where-Object {($_.Status -eq "Closed")}).Count)"
    Write-Host "|`n+---------------------------------------------------------------------------------------`n"
    Write-Host "Script duration:`t$ExecutionTimeMinutes Minutes $ExecutionTimeSeconds Seconds`n" -ForegroundColor Yellow
    Write-Host "Script ($ScriptFileName) exit at $EndTime`n" -ForegroundColor Green
            
    # Return custom psobject with Port status
    if($IncludeClosed) { return $Results } else { return $Results | Where-Object {$_.Status -eq "Open"} } 
}