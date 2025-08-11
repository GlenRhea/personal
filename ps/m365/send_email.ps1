param ($subject, $body)

$username = "user@domain.com"
$password = 'Password123!' # Use a secure method to handle passwords in production
$secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force 
$creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $secureStringPwd)

## Define the Send-MailMessage parameters
$mailParams = @{
    SmtpServer                 = 'smtp.office365.com'
    Port                       = '587' # or '25' if not using TLS
    UseSSL                     = $true ## or not if using non-TLS
    Credential                 = $creds
    From                       = $username
    To                         = 'recipient@NotYourDomain.com' #, 'recipient@NotYourDomain.com'
    Subject                    = $subject
    Body                       = $body
    #DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
}

## Send the message
try {
    Send-MailMessage @mailParams
} catch {
    write-host "There was an error sending the email!"
    Write-Host $_.Exception.Message`n
}