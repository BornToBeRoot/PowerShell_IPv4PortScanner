# PowerShell Async Port-Scanner

Powerful asynchronus Port-Scanner which returns a custom PowerShell-Object with basic informations about the scanned Port-Range include Port-Number, Protocol, Service-Name, Service-Description and Status.

## Description

This is a powerful asynchronus Port-Scanner working with the PowerShell RunspacePool. You can scan any Port-Range you want. The result will show you all open ports Port-Number, Protocol, Service-Name, Service-Description and Status.
    
This script also work fine along with my [asychronus IP-Scanner](https://github.com/BornToBeRoot/PowerShell_Async-IPScanner) published on GitHub too. You can easily pipe the output of the IP-Scanner result in this script.

![Screenshot of Working Scanner and Result](https://github.com/BornToBeRoot/PowerShell_Async-PortScanner/blob/master/Documentation/ScanPortsAsync_Result.png?raw=true)

## Syntax

```powershell
.\ScanPortsAsync.ps1 [-ComputerName] <String> [[-StartPort] <Int32>] [[-EndPort] <Int32>] [[-Threads] <Int32>] [[-UpdateListFromIANA]] [[-Force]] [<CommonParameters>]
```

## Example

Scan a specific Port-Range (1-500)

```powershell
.\ScanPortsAsync.ps1 -ComputerName 192.168.1.100 -StartPort 1 -EndPort 500 | Format-Table
``` 

You may want to update the official "Service Name and Transport Protocol Port Number Registry" from IANA... Just add the parameter "-UpdateListFromIANA".

```powershell
.\ScanPortsAsync.ps1 -ComputerName 172.16.2.5 -UpdateListFromIANA
``` 
If your PC has enough power, you can use more threads at the same time

```powershell
.\ScanPortsAsync.ps1 -ComputerName test-pc01 -Threads 250
```

## Output 

```powershell
Port Protocol ServiceName  ServiceDescription               Status
---- -------- -----------  ------------------               ------
  21 tcp      ftp          File Transfer Protocol [Control] open
  53 tcp      domain       Domain Name Server               open
  80 tcp      http         World Wide Web HTTP              open
 139 tcp      netbios-ssn  NETBIOS Session Service          open
 445 tcp      microsoft-ds Microsoft-DS                     open
``` 

and if no port list is available (should never happend, because it's uploaded on Github)

```powershell
Port Protocol Status
---- -------- ------
  21 tcp      open
  53 tcp      open
  80 tcp      open
 139 tcp      open
 445 tcp      open
```

## Offical Port List

* [Service Name and Transport Protocol Port Number Registry - IANA.org](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml)

## ToDo
[x] Integrate Port-List like: 80 (http), 443 (https), etc.

[x] You can now enter a hostname as -ComputerName. The script will resolve the IPv4-Address.
