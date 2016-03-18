# PowerShell Async Port-Scanner

Powerful asynchronus Port-Scanner which returns a custom PowerShell-Object with basic informations about the scanned Port-Range include port number, protocol, service name, service description and status.

## Description

This is a powerful asynchronus Port-Scanner working with the PowerShell RunspacePool. You can scan any Port-Range you want. The Result will show you all open ports port number, protocol, service name, service description and status.
    
This script also work fine along with my asychronus IP-Scanner published on GitHub too. You can easily pipe the output of the IP-Scanner result in this script.

![Screenshot of Working Scanner and Result](https://github.com/BornToBeRoot/PowerShell_Async-PortScanner/blob/master/Screenshots/Working_and_Result.png?raw=true)

## Syntax

```powershell
.\ScanPortsAsync.ps1 [-IPv4Address] <IPAddress> [[-StartPort] <Int32>] [[-EndPort] <Int32>] [[-Threads] <Int32>] [[-UpdateListFromIANA]] [<CommonParameters>]
```

## Example

Scan a specific Port-Range (1-500)

```powershell
.\ScanPortsAsync.ps1 -IPv4Address 192.168.1.100 -StartPort 1 -EndPort 500 | Format-Table
``` 

You may want to update the official Service Name and Transport Protocol Port Number Registry from IANA... Just add the parameter "-UpdateListFromIANA".

```powershell
.\ScanPortsAsync.ps1 -IPv4Address 172.16.2.5 -UpdateListFromIANA
``` 
If your PC has enough power, you can use more threads at the same time

```powershell
.\ScanPortsAsync.ps1 -IPv4Address 172.16.2.5 -Threads 250
``` 

## Output 

```powershell
Port Protocol Service Name Service Description              Status
---- -------- ------------ -------------------              ------
  21 tcp      ftp          File Transfer Protocol [Control] open
  53 tcp      domain       Domain Name Server               open
  80 tcp      http         World Wide Web HTTP              open
  80 tcp      www          World Wide Web HTTP              open
  80 tcp      www-http     World Wide Web HTTP              open
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
