#install all the things
clear

### Install Apps silent ###
function install_silent {
    Clear-Host
    
    Pause
}

#$apps = @("Scintilla.SciTE","Ghisler.TotalCommander","7zip.7zip","WinSCP.WinSCP","Git.Git","Microsoft.VisualStudioCode","Microsoft.VisualStudio.2022.Professional","Microsoft.SQLServerManagementStudio","9P7KNL5RWT25","Mozilla.Firefox","Microsoft.PowerShell")
#SS
#$apps = @("Scintilla.SciTE","Ghisler.TotalCommander","7zip.7zip","WinSCP.WinSCP","Git.Git","Microsoft.VisualStudioCode","Microsoft.SQLServerManagementStudio","9P7KNL5RWT25","Mozilla.Firefox","Microsoft.PowerShell","Microsoft.AzureDataStudio")
#ITC
$apps = @("Scintilla.SciTE","Ghisler.TotalCommander","7zip.7zip","WinSCP.WinSCP","Git.Git","Microsoft.VisualStudioCode","9P7KNL5RWT25","Microsoft.PowerShell","Spotify.Spotify")


Write-Host -ForegroundColor Cyan "Installing new Apps"
foreach ($app in $apps) {
    echo "********* Installing: $app *********"
    #winget.exe install -h --accept-package-agreements --accept-source-agreements $app
    #winget.exe install -h $app
    
    
        $listApp = winget list --exact --accept-source-agreements -q $app
        if (![String]::Join("", $listApp).Contains($app)) {
            Write-Host -ForegroundColor Yellow  "Install:" $app
            # MS Store apps
            if ((winget search --exact -q $app) -match "msstore") {
                winget install --exact --silent --accept-source-agreements --accept-package-agreements $app --source msstore
            }
            # All other Apps
            else {
                winget install --exact --silent --scope machine --accept-source-agreements --accept-package-agreements $app
            }
            if ($LASTEXITCODE -eq 0) {
                Write-Host -ForegroundColor Green "$app successfully installed."
            }
            else {
                #$app + " couldn't be installed." | Add-Content $errorlog
                Write-Warning "$app couldn't be installed."
                #Write-Host -ForegroundColor Yellow "Write in $errorlog"
                Pause
            }  
        }
        else {
            Write-Host -ForegroundColor Yellow "$app already installed. Skipping..."
        }
    
}

