#global variables here
#call the functions and variables script
. .\onb_audit_variables.ps1

function Output-Log {
    Param( 
           [Parameter(Mandatory)]
           [ValidateSet('info','warn', 'error')]
           [alias("L")] 
           [string]$LogLevel, 
    
           [alias("M")] 
           [string]$msg
       ) 
       $outputPath = "$logOutputPath\modules\output.txt"
       $date = Get-Date
       #$date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
       $output = $date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
       #only output to the console if set to verbose, otherwise everything is in the log file
       if ($Verbose) {
            switch ($LogLevel) {
                warn { Write-Host -ForegroundColor Yellow $output}
                error { Write-Host -ForegroundColor Red $output}
                Default { Write-Host -ForegroundColor Green $output }
            }
       }
       
    
    if (!(Test-Path $outputPath)) {
        $null = New-Item -ItemType File -Force -Path $outputPath
    } else {
        $output | Out-File -FilePath $outputPath -Append
    }
}


function ZipFile {
    Param( 
           [Parameter(Mandatory)]
           [alias("P")] 
           [string]$InputPath,
               
           [Parameter(Mandatory)]
           [alias("D")] 
           [string]$DestinationPath
        )

    $compress = @{
    Path = "$InputPath"
    CompressionLevel = "Fastest"
    DestinationPath = "$DestinationPath"
    }
    
    try {
        if (Test-Path "c:\Program Files\7-Zip\7z.exe") {
            #7zip is installed, let's use that first
            if (!(Test-Path $DestinationPath)) {
                ."c:\Program Files\7-Zip\7z.exe" a -tzip $DestinationPath $InputPath > $null
            }
        } else {
            if (!(Test-Path $DestinationPath)) {
                Compress-Archive @compress
            }
        }            
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Output-Log -L "error" -M "FUNC - ZIP - The error is: $ErrorMessage"
        Exit 1
    }
    
}

function SendEmail {
    Param( 
        [Parameter(Mandatory)]
        [alias("S")] 
        [string]$subject,
            
        [Parameter(Mandatory)]
        [alias("B")] 
        [string]$body,

        [Parameter(Mandatory)]
        [alias("F")] 
        [string]$filename
    )
        #param ($subject, $body)

    $username = "username@company.com"
    $password = 'password'
    $secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force 
    $creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $secureStringPwd)

    ## Define the Send-MailMessage parameters
    $mailParams = @{
        SmtpServer                 = 'smtp.office365.com'
        Port                       = '587' # or '25' if not using TLS
        UseSSL                     = $true ## or not if using non-TLS
        Credential                 = $creds
        From                       = $username
        To                         = $sendTo #, 'recipient@NotYourDomain.com'
        Subject                    = $subject
        Body                       = $body
        Attachments                = "$filename"
        #DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
    }
    
    ## Send the message
    try {
        Send-MailMessage @mailParams
        Output-Log -L "info" -M "FUNC - Mail - Sent email to $sendTo from $username with subject $subject and attachment $filename"
    } catch {
        $ErrorMessage = $_.Exception.Message
        Output-Log -L "error" -M "FUNC - Mail - The error is: $ErrorMessage"
    }
}
