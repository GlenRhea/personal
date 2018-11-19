#this script does all the required steps to setup a SFTP user
#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory
#Requires -Modules NTFSSecurity
clear
#functions
#logging function
function Output-Log {
 Param( 
        [alias("L")] 
        [string]$LogLevel, 
 
        [alias("M")] 
        [string]$msg
    ) 
	$date = Get-Date
	$date.toString() + " [" + $LogLevel.toUpper() + "]`t $msg"
}

#get username and environment
$found = $false
Do {
		$username = read-host "Please enter the username"
		If (Get-ADUser -Filter "SamAccountName -eq '$userName'") {
			Output-Log -L "info" -M "Username exists in AD, try again!"
		} Else {    
			Write-Output "Username does NOT exist in AD, continuing..."
			$found = $true
		}
} Until ($found)
#get environment
$found = $false
Do {
		$env = read-host "Is this prod or eval data? (prod/eval) "
		switch ($env.toLower()){
			prod {$ftppath = "x:\ftproot\data\$username"
				Output-Log -L "info" -M "Using the prod env with the path $ftppath"
				$found = $true
				; break} #prod
			eval {$ftppath = "x:\ftproot\data\_Evaluations\$username"
				Output-Log -L "info" -M "Using the eval env with the path $ftppath"
				$found = $true
				; break} #eval
			default {
				Output-Log -L "ERROR" -M "Please enter the environment!"
				; break}
		}
} Until ($found)

Output-Log -L "info" -M "Generating a complex password..."
Try {
	. ./NewPassword.ps1
	$pw = New-Password -length 18 -U -L -N -S
	Output-Log -L "info" -M "The password has been generated and will be saved in KeePass."
	Output-Log -L "info" -M "The password is ""$pw"" (between the first and last double quotes!)"
	Read-Host -Prompt "Press Enter to continue..."
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "The password generating code could not be loaded. The error is: $ErrorMessage"
	Exit 1
}

#create ad user
$path = "OU=BitViseUsers,OU=company,DC=company,DC=local"
#create the user
Try {
	Output-Log -L "info" -M "Creating the new user..."
	$password = ConvertTo-SecureString -String $pw -AsPlainText -Force
	New-ADUser -SAMAccountName $username -Name "$username bitvise" -UserPrincipalName "$username@company.local" -DisplayName "$username bitvise" -GivenName $username -SurName "bitvise" -AccountPassword $password -Enabled $true -Path $path -PasswordNeverExpires $true -CannotChangePassword $true -ErrorAction Stop
	#add the new user to the bitvise group
	Add-ADGroupMember "bitvise users" $username
	#change the primary group first
	$group = get-adgroup "bitvise users" -properties @("primaryGroupToken")
	get-aduser "$username" | set-aduser -replace @{primaryGroupID=$group.primaryGroupToken}
	#remove them from the domain users group
	Remove-ADGroupMember "Domain Users" "$username" -Confirm:$false
	Output-Log -L "info" -M "Created the new AD user successfully!"
} Catch {
  $ErrorMessage = $_.Exception.Message
  Output-Log -L "ERROR" -M "Unable to create the user properly. The error is: $ErrorMessage"
  Exit 1
}

#add to bitvise
Try {
	#create the bitvise object
	Output-Log -L "info" -M "Adding the user to bitvise..."
	$cfg = new-object -com "BssCfg714.BssCfg714" -ErrorAction Stop
	#lock and load the database
	$cfg.LockServerSettings()
	$cfg.LoadServerSettings()
	#change settings
	$cfg.settings.access.winAccountsEx.new.winAccount = "$username"
	$cfg.settings.access.winAccountsEx.new.winDomain = "company"
	$cfg.settings.access.winAccountsEx.new.winAccountType = 2
	$cfg.settings.access.winAccountsEx.new.specifyGroup = $cfg.DefaultYesNo.yes
	$cfg.settings.access.winAccountsEx.new.groupType = 0
	$cfg.settings.access.winAccountsEx.new.loginAllowed = $cfg.DefaultYesNo.yes
	$cfg.settings.access.winAccountsEx.new.xfer.mountPointsEx.Clear()
	$cfg.settings.access.winAccountsEx.new.xfer.mountPointsEx.new.realRootPath = "$ftppath"
	$cfg.settings.access.winAccountsEx.new.xfer.mountPointsEx.NewCommit()
	$cfg.settings.access.winAccountsEx.NewCommit()
	#close database
	#save and unlock the settings
	$cfg.SaveServerSettings()
	$cfg.UnlockServerSettings()
	Output-Log -L "info" -M "Added the user to bitvise!"
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "Bitvise setup failed. The error is: $ErrorMessage"
	#so we don't lock the settings database!
	$cfg.UnlockServerSettings()
  Exit 1
}


#add to keepass
#needs the scripting plugin for keepass: http://keepass.info/help/v2_dev/scr_sc_index.html
Try {
	Output-Log -L "info" -M "Adding the user to keepass..."
	#use the 
	#-guikeyprompt 
	# -GroupName:"Internet Sites"
	# "c:\Program Files (x86)\KeePass Password Safe 2\KPScript" -c:AddEntry "\\company.local\Public\company\IT\KeePass\company.kdbx" -guikeyprompt -Title:$username -UserName:$username -Password:$pw -GroupPath:"company/company FTP Accounts/$username"
	Start-Process -Wait -FilePath "c:\Program Files (x86)\KeePass Password Safe 2\KPScript" -ArgumentList "-c:AddEntry ""\\company.local\Public\company\IT\KeePass\company.kdbx"" -guikeyprompt -Title:$username -UserName:$username -Password:$pw -GroupPath:""company/company FTP Accounts/$username"" -URL:""sftp://sftp.company.com"""
	Output-Log -L "info" -M "Added the user to keepass!"
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "KeePass setup failed. The error is: $ErrorMessage"
  Exit 1
}

#create folder & add file permissions
#needs this module for the permissions: https://goo.gl/OcFqgi
#you have to put this at the end so the AD account will work for the permissions.
Try {
	Output-Log -L "info" -M "Creating the folder and adding permissions..."
	
	md $ftppath > $null
	#make the incoming and outgoing folders
	md "$ftppath\Incoming" > $null
	md "$ftppath\Outgoing" > $null
	#set permissions
	Get-Item $ftppath | Add-NTFSAccess -Account company\$username -AccessRights FullControl
	Output-Log -L "info" -M "Created the folder and permissions!"
} Catch {
	$ErrorMessage = $_.Exception.Message
	Output-Log -L "ERROR" -M "Unable to create folder or add permissions!. The error is: $ErrorMessage"
  Exit 1
}