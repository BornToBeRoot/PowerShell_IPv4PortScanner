###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  ScanPortsAsync.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Asynchronus Port Scanner for PowerShell
# Repository   :  https://github.com/BornToBeRoot/PowerShell_Async-PortScanner
###############################################################################################################

<#
    .SYNOPSIS
    Powerful asynchronus Port-Scanner which returns a custom PowerShell-Object with basic informations about the 
    scanned Port-Range include Port-Number, Protocol, Service-Name, Service-Description and Status.
    
    .DESCRIPTION
    This is a powerful asynchronus Port-Scanner working with the PowerShell RunspacePool. You can scan any 
    Port-Range you want. The result will show you all open ports with include Port-Number, Protocol, 
    Service-Name, Service-Description and Status.
    
    This script also work fine along with my asychronus IP-Scanner published on GitHub too. You can easily
    pipe the output of the IP-Scanner result in this script.
    If you found a bug or have some ideas to improve this script... Let me know. You find my Github profile in
    the links below.
    
    .EXAMPLE
    .\ScanPortsAsync.ps1 -IPv4Address 172.16.0.1 -StartPort 1 -EndPort 1000
    
    .EXAMPLE
    .\ScanPortsAsync.ps1 -IPv4Address 192.168.1.100 -UpdateListFromIANA

    .EXAMPLE
    .\ScanPortsAsync.ps1 -IPv4Address 192.168.1.100 -Threads 250
    
    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell_Async-PortScanner
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
        HelpMessage='Enter the Start-Port (Default=1)')]
    [Int32]$StartPort=1,

    [Parameter(
        Position=2,
        HelpMessage='Enter the End-Port (Default=65535)')]
    [Int32]$EndPort=65535,

    [Parameter(
        Position=3,
        HelpMessage='Set the maximum number of threads at the same time (Default=100)')]
    [Int32]$Threads=100,

    [Parameter(
        Position=4,
        HelpMessage='Update Service Name and Transport Protocol Port Number Registry from IANA.org (https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml)')]
    [Switch]$UpdateListFromIANA
)

Begin{
    # Time when the script starts
    $StartTime = Get-Date 
    
    # Script Path and FileName
    $Script_Startup_Path = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ScriptFileName = $MyInvocation.MyCommand.Name
    
    # IANA -> Service Name and Transport Protocol Port Number Registry -> XML-File
    $IANA_PortList_WebUri = "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml"
   
    # Local path to PortList
    $XML_PortList_Path = "$Script_Startup_Path\ServiceName_and_TransportProtocolPortNumber_Registry.xml"
    
	# Port list can be updated from IANA.org with the parameter "-UpdateListFromIANA
    if($UpdateListFromIANA)
    {
        try
        {
            Write-Host "Updating Service Name and Transport Protocol Port Number Registry from IANA.org...`t" -ForegroundColor Gray -NoNewline

            [xml]$New_XML_PortList = Invoke-WebRequest -Uri $IANA_PortList_WebUri # Download latest xml-file from IANA

            if([System.IO.File]::Exists($XML_PortList_Path))
            {
                Remove-Item -Path $XML_PortList_Path
            }

            $New_XML_PortList.Save($XML_PortList_Path) # Save xml-file

            Write-Host "OK" -ForegroundColor Green
        }
        catch
        {
            $ErrorMsg = $_.Exception.Message
            
            Write-Host "Update Service Name and Transport Protocol Port Number Registry from IANA.org failed with the follwing error message: $ErrorMsg"  -ForegroundColor Red
        }        
    }  
    elseif(-Not([System.IO.File]::Exists($XML_PortList_Path)))
    {   
        Write-Host 'No XML-File to assign service name with port number found! Use the parameter "-UpdateListFromIANA" to download the latest version from IANA.org. This warning doesn`t affect the scanning procedure.' -ForegroundColor Yellow
    }   
        
    if([System.IO.File]::Exists($XML_PortList_Path)) 
    { 
        $AssignServiceWithPorts = $true 
    } 
    else 
    { 
        $AssignServiceWithPorts = $false 
    }
	
    # Validate Port-Range
    if($StartPort -gt $EndPort)
    {
        Write-Host "Check your input! Invalid Port-Range... (-StartPort can't be lower than -EndPort)" -ForegroundColor Red 
        exit    
    }             

    if(-not( Test-Connection -ComputerName $IPv4Address -Count 2 -Quiet))
    {
        Write-Host "IP-Address not reachable!" -ForegroundColor Red
        exit
    }
    
    # Some User-Output about the selected or default settings
    Write-Host "`nScript ($ScriptFileName) started at $StartTime" -ForegroundColor Green
    Write-Host "`n+=-=-=-=-=-=-=-=-=-=-=-= Settings =-=-=-=-=-=-=-=-=-=-=-=`n|"
    Write-Host "| IP-Address:`t$IPv4Address"
    Write-Host "| Port-Range:`t$StartPort-$EndPort"
    Write-Host "| Threads:`t$Threads"
    Write-Host "|`n+========================================================`n"         
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
                $Status = "open"             
                $Socket.Close()
            }
        }
        catch
        {
            $Status = "closed"
        }
    
        $Result = New-Object -TypeName PSObject
        Add-Member -InputObject $Result -MemberType NoteProperty -Name Port -Value $Port
        Add-Member -InputObject $Result -MemberType NoteProperty -Name Protocol -Value "tcp"
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

	$PortRange = ($EndPort - $StartPort)
	
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
    $Jobs_Result = @()

    # Get results and fill the array
    foreach($Job in $Jobs)
    {
        $Jobs_Result += $Job.Pipe.EndInvoke($Job.Result)
    }

    # Only get open ports (others are closed -.- )
    $Ports_Open = $Jobs_Result | Where-Object {$_.Status -eq "open"}

    Write-Host "[" -ForegroundColor Gray -NoNewline; Write-Host "Done" -ForegroundColor Green -NoNewline; Write-Host "]" -ForegroundColor Gray	
    
    # Assign service with ports
    if($AssignServiceWithPorts)
    {
        Write-Host "Assign services to ports...`t`t" -ForegroundColor Yellow -NoNewline
        
        $XML_PortList = [xml](Get-Content -Path $XML_PortList_Path)

        $Ports_Open_Assigned = @()
        
        # Go through each port
        foreach($Port_Open in $Ports_Open)
        {
            # Go through each service
            foreach($XML_Node in $XML_PortList.Registry.Record)
            {
                # Find the right service (based on protocol and port number)
                if(($Port_Open.Protocol -eq $XML_Node.protocol) -and ($Port_Open.Port -eq $XML_Node.number))
                {
                    # Built new custom PSObject
                    $Port_Open_Assigned = New-Object -TypeName PSObject
                    Add-Member -InputObject $Port_Open_Assigned -MemberType NoteProperty -Name Port -Value $Port_Open.Port
                    Add-Member -InputObject $Port_Open_Assigned -MemberType NoteProperty -Name Protocol -Value $Port_Open.Protocol
                    Add-Member -InputObject $Port_Open_Assigned -MemberType NoteProperty -Name ServiceName -Value $XML_Node.name
                    Add-Member -InputObject $Port_Open_Assigned -MemberType NoteProperty -Name ServiceDescription -Value $XML_Node.description
                    Add-Member -InputObject $Port_Open_Assigned -MemberType NoteProperty -Name Status -Value $Port_Open.Status

                    # Add it to an array
                    $Ports_Open_Assigned += $Port_Open_Assigned

                    break # Don't show multiple results
                }
            }
        }        
        
        Write-Host "[" -ForegroundColor Gray -NoNewline; Write-Host "Done" -ForegroundColor Green -NoNewline; Write-Host "]" -ForegroundColor Gray	
    }
}

End{  
    # If no XML-File to assign service with port... only show open ports  
    if($AssignServiceWithPorts) 
    { 
        $Results = $Ports_Open_Assigned 
    } 
    else 
    { 
        $Results = $Ports_Open 
    }

	# Time when the Script finished
    $EndTime = Get-Date
        
	# Calculate the time between Start and End
    $ExecutionTimeMinutes = (New-TimeSpan -Start $StartTime -End $EndTime).Minutes
    $ExecutionTimeSeconds = (New-TimeSpan -Start $StartTime -End $EndTime).Seconds
        
    # Some User-Output with ports scanned/up and execution time
    Write-Host "`n+=-=-=-=-=-=-=-=-=-=-=-=  Result  =-=-=-=-=-=-=-=-=-=-=-=`n|"
    Write-Host "|  Ports Scanned:`t$($Jobs_Result.Count)"
    Write-Host "|  Ports Open:`t`t$(@($Results | Where-Object {($_.Status -eq "open")}).Count)"     
    Write-Host "|`n+========================================================`n"
    Write-Host "Script duration:`t$ExecutionTimeMinutes Minutes $ExecutionTimeSeconds Seconds`n" -ForegroundColor Yellow
    Write-Host "Script ($ScriptFileName) exit at $EndTime`n" -ForegroundColor Green
            
    # Return custom psobject with Port status
    return $Results
}
