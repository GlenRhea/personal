#Move-ADDirectoryServerOperationMasterRole -Identity ehnaz-adds-5 OperationMasterRole DomainNamingMaster,PDCEmulator,RIDMaster,SchemaMaster,InfrastructureMaster
$DC = "GARV-AZ-DC01"
Move-ADDirectoryServerOperationMasterRole -Identity $DC -OperationMasterRole 3,4
$DC = "GARV-AZ-DC02"
Move-ADDirectoryServerOperationMasterRole -Identity $DC -OperationMasterRole 0,1,2
<#
Tip. To simplify the command, you can replace the names of roles with numbers from 0 to 4. The correspondence of names and numbers is given in the table:

PDCEmulator	0
RIDMaster	1
InfrastructureMaster	2
SchemaMaster	3
DomainNamingMaster	4
#>

#keep getting permission denied, trying this one insteal
Invoke-Command -ComputerName $hostname -Credential $icred -ScriptBlock {

$global:ErrorActionPreference = "Stop";
import-module activedirectory;

Move-ADDirectoryServerOperationMasterRole -Identity owinfadc01 -Credential $icred -OperationMasterRole 0,1,2 -Force -Confirm:$false ;

}