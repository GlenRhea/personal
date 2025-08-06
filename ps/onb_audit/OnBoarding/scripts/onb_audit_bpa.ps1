#Requires -Modules ServerManager,BestPractices
#Requires -RunAsAdministrator

#references
#https://activedirectorypro.com/best-practices-analyzer-powershell/
#https://github.com/jeremyts/ActiveDirectoryDomainServices/blob/master/Audit/GenerateBPAReports.ps1

. .\onb_audit_functions.ps1

#let's make this generic 
<#
  This script will invoke the Best Practices Analyzer (BPA) on all valid server roles. 

  Notes:
    The BPA scan will fail if the PowerShell Execution Policy has been enabled via a GPO as per Microsoft TechNet article KB2028818.
    The BPA for the File Services role is only available after the installation of hotfix KB981111.


  It is based on the following script:
    - Invoke Best Practices Analyzer on remote servers using PowerShell by Jan Egil Ring:
      http://blog.powershell.no/2010/08/17/invoke-best-practices-analyzer-on-remote-servers-using-powershell 

  Release 1.1
  Modified by Jeremy@jhouseconsulting.com 12th December 2011
#>

#-------------------------------------------------------------
#& .\onb_audit_modules.ps1

# Get the script path
#$ScriptPath = {Split-Path $MyInvocation.ScriptName}
$ScriptPath = "$outputPath\modules\bpa"

if (!(Test-Path $ScriptPath)) {
    $null = New-Item -ItemType directory -Force -Path $ScriptPath
}
Output-Log info "All reports will be here: $ScriptPath"

#Initial variables, these must be customized 
$servers = @()
$CSVReport = $true 
$CSVReportPath = "$ScriptPath\BPAReports" 
$HTMLReport = $false 
$HTMLReportPath = "$ScriptPath\BPAReports" 
$ReportAllSevereties = $true 

# Change the value $oldTime in order to set a limit for files to be deleted.
$oldTime = [int]7 # 7 days

# Import the Modules
Import-Module ServerManager
Import-Module BestPractices

Try {
    #disable the annoying progress bars
    $OriginalProgressPreference = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'
    
        $ModelsToRun = @()
        #$Server = $Server.DNSHostName
        $Server = hostname
        Output-Log info "BPA - Working on $Server."
        
        $prescan = get-bpamodel | select ID, Name, lastscantime
        Output-Log info "BPA - Checking for last BPA scan date/time"
        $roles = Get-WindowsFeature | Where-Object {$_. installstate -eq "installed"} | select Name,Installstate 
        Output-Log info "BPA - Getting all roles from $server."

        #now search for the role from the object array
        foreach ($role in $roles) {
            switch ($role.Name) {
                "AD-Domain-Services" {
                    $ModelsToRun += "Microsoft/Windows/DirectoryServices"
                    & .\onb_audit_modules.ps1 "SecurityFever"
                    & .\onb_audit_ad.ps1
                }
                "DHCP" {$ModelsToRun += "Microsoft/Windows/DHCPServer"}
                "DNS" {
                    $ModelsToRun += "Microsoft/Windows/DNSServer"
                    Output-Log info "DNS - Checking for DNS Modules"
                    & .\onb_audit_modules.ps1 "DomainHealthChecker"
                    & .\onb_audit_dns.ps1                    
                    }
                "Hyper-V" {
                    $ModelsToRun += "Microsoft/Windows/Hyper-V"
                    & .\onb_audit_hyperv.ps1
                    }
                "FS-FileServer" {
                    $ModelsToRun += "Microsoft/Windows/FileServices"
                    Output-Log info "FS - Checking for FS Modules"
                    & .\onb_audit_modules.ps1 "NTFSSecurity"
                    #& .\onb_audit_modules.ps1 "ActiveDirectory"
                    & .\onb_audit_fs.ps1                    
                    }
                "Web-WebServer" {$ModelsToRun += "Microsoft/Windows/WebServer"}
                "Remote-Desktop-Services" {$ModelsToRun += "Microsoft/Windows/TerminalServices"}
                "UpdateServices" {$ModelsToRun += "Microsoft/Windows/UpdateServices"}
                "Adcs-Cert-Authority" {$ModelsToRun += "Microsoft/Windows/CertificateServices"}
                "NPAS" {$ModelsToRun += "Microsoft/Windows/NPAS"}
            }
        }
                                
        if ($ModelsToRun.Count -ne 0) {

            foreach ($BestPracticesModelId in $ModelsToRun) { 

            #Path-variables 
            $date = Get-Date -Format "dd-MM-yy_HH-mm" 
            $BPAName = $BestPracticesModelId.Replace("Microsoft/Windows/","") 
            #$CSVPath = $CSVReportPath+"\"+$server.Name+"-"+$BPAName+"-"+$date+".csv" 
            $CSVPath = "$CSVReportPath\$server-$BPAName-$date.csv" 
            $HTMLPath = $HTMLReportPath+"\"+$server.Name+"-"+$BPAName+"-"+$date+".html" 
        
            #HTML-header 
            $Head = "
            <title>BPA Report for $BestPracticesModelId on $server.Name</title>
            <style type='text/css'>
                table  { border-collapse: collapse; width: 700px }
                body   { font-family: Arial }
                td, th { border-width: 2px; border-style: solid; text-align: left; padding: 2px 4px; border-color: black }  
                th     { background-color: grey }
                td.Red { color: Red }
            </style>"

            #Invoke BPA Model 
            Output-Log info "BPA - Invoking the $BPAName model on $Server"
            #Invoke-BpaModel -ComputerName $Server -BestPracticesModelId $BestPracticesModelId | Out-Null 
            Invoke-BpaModel -BestPracticesModelId $BestPracticesModelId | Out-Null 
        
            #Include all severeties in BPA Report if enabled. If not, only errors and warnings are reported. 
            if ($ReportAllSevereties) { 
                $BPAResults = Get-BpaResult -BestPracticesModelId $BestPracticesModelId 
            } 
                else 
            { 
                $BPAResults = Get-BpaResult -BestPracticesModelId $BestPracticesModelId | Where-Object {$_.Severity -eq "Error" -or $_.Severity -eq "Warning" } 
                #$BPAResults = Get-BpaResult -BestPracticesModelId $BestPracticesModelId | Where-Object {$_.Severity -ne "Information"} 
            } 
            
            Output-Log info "BPA - Getting the results of $BPAName model on $Server"

            #Send BPA Results to CSV-file if enabled 
            if ($BPAResults -and $CSVReport) {
                if (!(Test-Path -path $CSVReportPath)) {
                New-Item $CSVReportPath -type directory | out-Null
                } else {
            # Deleting the old files
            Get-ChildItem -Path "$CSVReportPath" -Recurse -Include "*.csv" | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | Remove-Item -Force
                }
                $BPAResults | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $CSVPath -Encoding utf8
            } 
        
            #Send BPA Results to HTML-file if enabled 
            if ($BPAResults -and $HTMLReport) { 
                if (!(Test-Path -path $HTMLReportPath)) {
                New-Item $HTMLReportPath -type directory | out-Null
                } else {
                # Deleting the old files
            Get-ChildItem -Path "$HTMLReportPath" -Recurse -Include "*.html" | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | Remove-Item -Force
                }
                $BPAResults | ConvertTo-Html -Property Severity,Category,Title,Problem,Impact,Resolution,Help -Title "BPA Report for $BestPracticesModelId on $($server.Name)" -Body "BPA Report for $BestPracticesModelId on server $($server.Name) <HR>" -Head $head | Out-File -FilePath $HTMLPath 
            } 
            }
        }
        
    
    #re-enable the progress bars
    $Global:ProgressPreference = $OriginalProgressPreference
} catch {
    $errorLine = $PSItem.InvocationInfo.ScriptLineNumber
    #we will catch any errors here and output them
    $ErrorMessage = $_.Exception.Message
    Output-Log -L "error" -M "The error on line # $errorLine is: $ErrorMessage"
}
