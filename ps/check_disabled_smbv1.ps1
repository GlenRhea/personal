Try {
	$output = Get-SmbServerConfiguration | Select EnableSMB1Protocol
	Write-Host ($output) 
     if ($output -match "False") {
				Write-Host "Script Check Passed"
				Exit 0	
		} else {
				Write-Host("Script Check Failed") 
				Exit 1001
		}
  }
Catch 
    {
     Write-Host("Script Check Failed in Catch") 
     Exit 1001
    }