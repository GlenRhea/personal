# Populate your User variable
$Users = Get-Aduser -Filter * -Properties nTSecurityDescriptor

#StartLoop1: Check for disabled security inheritance
ForEach ($User in $Users) { 
    #Here's the check
	 echo $user.Name
    If ($user.nTSecuirtyDescrioptor.AreAccessRulesProtected -eq $False) {
        #Whatever output you want goes here
		  echo $user
    } 
} #EndLoop1