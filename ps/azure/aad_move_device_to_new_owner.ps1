#NOTE: I had to run this in the cloud shell, no matter how I logged in it wouldn't work on my workstation
$scanner = "userguidhere"
$admin = "userguidhere"

#get all devices
$devices = Get-AzureADDevice -All $true | Where-Object {$_.DeviceTrustType -eq “AzureAd”}|Select-Object ObjectId

foreach ($device in $devices) {
    $device = $device.ObjectId
    #add new owner
    Add-AzureADDeviceRegisteredOwner -ObjectId $device -RefObjectId $scanner
    #lets pause a bit just in case
    Start-Sleep 5
    #remove from admin account
    Remove-AzureADDeviceRegisteredOwner -ObjectId $device -OwnerId $admin
}