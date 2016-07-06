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
    This powerful asynchronus IPv4 Port Scanner allows you to scan every Port-Range you want (500 to 2600 would work). Only TCP-Ports are scanned. 

    The result will contain the Port number, Protocol, Service name, Description and the Status.
    
    .EXAMPLE
    .\New-IPv4PortScan.ps1 -ComputerName fritz.box -EndPort 500

    Port Protocol ServiceName  ServiceDescription               Status
    ---- -------- -----------  ------------------               ------
      21 tcp      ftp          File Transfer Protocol [Control] open
      53 tcp      domain       Domain Name Server               open
      80 tcp      http         World Wide Web HTTP              open
    
    .LINK
    https://github.com/BornToBeRoot/PowerShell_IPv4PortScanner/blob/master/README.md
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
        HelpMessage='Maximum number of threads at the same time (Default=500)')]
    [Int32]$Threads=500,

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

            $_.Exception.Message  
        }
    } 

    # Function to assign service with port
    function AssignServiceWithPort
    {
        param(
            $Result
        )

        Begin{

        }

        Process{
            $Service = [String]::Empty
            $Description = [String]::Empty
                        
            foreach($XML_Node in $XML_PortList.Registry.Record)
            {                
                if(($Result.Protocol -eq $XML_Node.protocol) -and ($Result.Port -eq $XML_Node.number))
                {
                    $Service = $XML_Node.name
                    $Description = $XML_Node.description
                    break
                }
            }
                
            $NewResult = [pscustomobject] @{
                Port = $Result.Port
                Protocol = $Result.Protocol
                ServiceName = $Service
                ServiceDescription = $Description
                Status = $Result.Status
            }

            return $NewResult
        }  

        End{

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
        Write-Host 'No xml-file to assign service with port found! Use the parameter "-UpdateList" to download the latest version from IANA.org. This warning doesn`t affect the scanning procedure.' -ForegroundColor Yellow
    }

    # Check if it is possible to assign service with port --> import xml-file
    if([System.IO.File]::Exists($XML_PortList_Path))
    {
        $AssignServiceWithPort = $true

        $XML_PortList = [xml](Get-Content -Path $XML_PortList_Path)
    }
    else 
    {
        $AssignServiceWithPort = $false    
    }

    # Validate Port-Range
    if($StartPort -gt $EndPort)
    {
        Write-Host "Invalid Port-Range... Check your input!" -ForegroundColor Red
        return
    }

    # Check if host is reachable
    Write-Verbose "Test if host is reachable..."
    if(-not(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet))
    {
        Write-Host "$ComputerName is not reachable!" -ForegroundColor Red

        if($Force -eq $false)
        {
            do {
                $Answer = Read-Host "Would you like to continue? (perhaps only ICMP is blocked) [yes|no]"

            } while("yes","y","no","n" -notcontains $Answer)
        
            if("no","n" -contains $Answer)
            {
                return
            }
        }
    }

    $PortsToScan = ($EndPort - $StartPort)

    Write-Verbose "Scanning range from $StartPort to $EndPort ($PortsToScan Ports)"
    Write-Verbose "Running with max $Threads threads"

    # Check if ComputerName is already an IPv4-Address, if not... try to resolve it
    $IPv4Address = [String]::Empty
	
	if([bool]($ComputerName -as [IPAddress]))
	{
		$IPv4Address = $ComputerName
	}
	else
	{
		# Get IP from Hostname (IPv4 only)
		try{
			$AddressList = @(([System.Net.Dns]::GetHostEntry($ComputerName)).AddressList)
			
			foreach($Address in $AddressList)
			{
				if($Address.AddressFamily -eq "InterNetwork") 
				{					
					$IPv4Address = $Address.IPAddressToString 
					break					
				}
			}					
		}
		catch{ }	# Can't get IPAddressList 					

       	if([String]::IsNullOrEmpty($IPv4Address))
		{
			Write-Host "Could not get IPv4-Address for $ComputerName. (Try to enter an IPv4-Address instead of the Hostname)" -ForegroundColor Red
            return
		}		
	}

    # Scriptblock --> will run in runspaces (threads)...
    [System.Management.Automation.ScriptBlock]$ScriptBlock = {
        Param(
			$IPv4Address,
			$Port
        )

        try{                      
            $Socket = New-Object System.Net.Sockets.TcpClient($IPv4Address,$Port)
            
            if($Socket.Connected)
            {
                $Status = "Open"             
                $Socket.Close()
            }
            else 
            {
                $Status = "Closed"    
            }
        }
        catch{
            $Status = "Closed"
        }   

        $Result = [pscustomobject] @{
            Port = $Port
            Protocol = "tcp"
        	Status = $Status
        }

        return $Result
    }

    Write-Verbose "Setting up RunspacePool..."

    # Create RunspacePool and Jobs
    $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $Threads, $Host)
    $RunspacePool.Open()
    [System.Collections.ArrayList]$Jobs = @()

    Write-Verbose "Setting up Jobs..."
    
    #Set up job for each port...
    foreach($Port in $StartPort..$EndPort)
    {
        $ScriptParams =@{
			IPv4Address = $IPv4Address
			Port = $Port
		}

        # Catch when trying to divide through zero
        try {
			$Progress_Percent = (($Port - $StartPort) / $PortsToScan) * 100 
		} 
		catch { 
			$Progress_Percent = 100 
		}

        Write-Progress -Activity "Setting up jobs..." -Id 1 -Status "Current Port: $Port"  -PercentComplete ($Progress_Percent)
        
        # Create mew job
        $Job = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock).AddParameters($ScriptParams)
        $Job.RunspacePool = $RunspacePool
        
        $JobObj = [pscustomobject] @{
            RunNum = $Port - $StartPort
            Pipe = $Job
            Result = $Job.BeginInvoke()
        }

        # Add job to collection
        [void]$Jobs.Add($JobObj)
    }

    Write-Verbose "Waiting for jobs to complete & starting to process results..."

    # Total jobs to calculate percent complete, because jobs are removed after they are processed
    $Jobs_Total = $Jobs.Count

     # Process results, while waiting for other jobs
    Do {
        # Get all jobs, which are completed
        $Jobs_ToProcess = $Jobs | Where-Object {$_.Result.IsCompleted}
  
        # If no jobs finished yet, wait 500 ms and try again
        if($Jobs_ToProcess -eq $null)
        {
            Write-Verbose "No jobs completed, wait 500ms..."

            Start-Sleep -Milliseconds 500
            continue
        }
        
        # Get jobs, which are not complete yet
        $Jobs_Remaining = ($Jobs | Where-Object {$_.Result.IsCompleted -eq $false}).Count

        # Catch when trying to divide through zero
        try {            
            $Progress_Percent = 100 - (($Jobs_Remaining / $Jobs_Total) * 100) 
        }
        catch {
            $Progress_Percent = 100
        }

        Write-Progress -Activity "Waiting for jobs to complete... ($($Threads - $($RunspacePool.GetAvailableRunspaces())) of $Threads threads running)" -Id 1 -PercentComplete $Progress_Percent -Status "$Jobs_Remaining remaining..."
      
        Write-Verbose "Processing $(if($Jobs_ToProcess.Count -eq $null){"1"}else{$Jobs_ToProcess.Count}) job(s)..."

        # Processing completed jobs
        foreach($Job in $Jobs_ToProcess)
        {       
            # Get the result...     
            $Job_Result = $Job.Pipe.EndInvoke($Job.Result)
            $Job.Pipe.Dispose()

            # Remove job from collection
            $Jobs.Remove($Job)
           
            # Check if result is null --> if not, return it
            if($Job_Result -ne $null -and $Job_Result.Status -eq "Open")
            {        
                if($AssignServiceWithPort)
                {
                    AssignServiceWithPort -Result $Job_Result
                }   
                else 
                {
                    $Job_Result    
                }             
            }
        } 

    } While ($Jobs.Count -gt 0)
    
    Write-Verbose "Closing RunspacePool and free resources..."

    # Close the RunspacePool and free resources
    $RunspacePool.Close()
    $RunspacePool.Dispose()

    Write-Verbose "Script finished at $(Get-Date)"
}

End{

}