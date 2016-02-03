# PowerShell Async PortScanner

Powerful asynchronus Port-Scanner which returns a custom PowerShell-Object with basic informations about the scanned Port-Range include Port and Status.

## Description

This is a powerful asynchronus Port-Scanner working with the PowerShell RunspacePool. You can scan any Port-Range you want. 
    
This script also work fine along with my asychronus IP-Scanner published on GitHub too. You can easily pipe the output of the IP-Scanner result in this script.

## Syntax

```powershell
.\ScanPortsAsync.ps1 [-IPv4Address] <IPAddress> [[-StartPort] <Int32>] [[-EndPort] <Int32>] [[-Threads] <Int32>] [[-IncludeClosed]] [<CommonParameters>]
```

## Example

Simple Port Scan
```powershell
.\ScanPortsAsync.ps1 -IPv4Address 192.168.1.100 -StartPort 1 -EndPort 5000
``` 

Show closed Ports in result
```powershell
.\ScanPortsAsync.ps1 -IPv4Address 172.16.2.5 -Threads 200 -IncludeClosed
``` 


## Output 

```powershell
Port Status
---- ------
  21 Open  
  80 Open  
 139 Open  
 443 Open
 445 Open  
```
  
## ToDo
- Integrate Port-List
 like: 80 (http), 443 (https) ...
