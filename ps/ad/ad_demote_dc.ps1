# Import the ADDSDeployment module
Import-Module ADDSDeployment

# Demote the server
Uninstall-ADDSDomainController -DemoteOperationMasterRole:$true -RemoveDnsDelegation:$true -Force:$true

# Run the following command after the reboot to remove the Active Directory Sites and Services
Uninstall-WindowsFeature AD-Domain-Services -IncludeManagementTools