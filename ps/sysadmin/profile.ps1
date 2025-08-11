#https://blogs.technet.microsoft.com/heyscriptingguy/2012/05/21/understanding-the-six-powershell-profiles/
#c:\Users\user\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1

$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
function prompt {
    #colorized prompt I use on *nix
    write-host -NoNewline -ForeGroundColor blue [
    Write-Host -NoNewline -ForeGroundColor gray $(get-date -format G)
    write-host -NoNewline -ForeGroundColor blue "]["
    write-host -NoNewline -ForeGroundColor magenta $currentuser.name
    write-host -nonewline -foregroundcolor darkgray "@"
    write-host -nonewline -foregroundcolor Cyan $(c:\windows\system32\hostname)
    write-host -ForeGroundColor blue ]
    write-host -ForeGroundColor yellow $(get-location)
    write-host -NoNewline -ForeGroundColor Cyan "$";" "
}
#functions for the aliases
function fdocs{Set-Location $ENV:UserProfile\Documents}
function fcode{Set-Location $ENV:UserProfile\Documents\work\code}
function fproj{Set-Location $ENV:UserProfile\Documents\work\projects}
function ftemp{Set-Location C:\temp}
function fit{Set-Location x:\IT}

function fLL
{
    param ($dir = ".", $all = $false) 

    $origFg = $host.ui.rawui.foregroundColor 
    if ( $all ) { $toList = ls -force $dir }
    else { $toList = ls $dir }

    foreach ($Item in $toList)  
    { 
        Switch ($Item.Extension)  
        { 
             ".Exe" {$host.ui.rawui.foregroundColor = "Yellow"} 
	    ".msi" {$host.ui.rawui.foregroundColor = "Yellow"} 
	    ".msu" {$host.ui.rawui.foregroundColor = "Yellow"} 
	    ".zip" {$host.ui.rawui.foregroundColor = "Blue"} 
	    ".iso" {$host.ui.rawui.foregroundColor = "Blue"} 
	    ".rar" {$host.ui.rawui.foregroundColor = "Blue"} 
	    ".tar" {$host.ui.rawui.foregroundColor = "Blue"} 
	    ".tar.gz" {$host.ui.rawui.foregroundColor = "Blue"} 
	    ".gz" {$host.ui.rawui.foregroundColor = "Blue"} 
            ".cmd" {$host.ui.rawui.foregroundColor = "Red"} 
            ".msh" {$host.ui.rawui.foregroundColor = "Red"} 
            ".vbs" {$host.ui.rawui.foregroundColor = "Red"} 
	    ".ps1" {$host.ui.rawui.foregroundColor = "Red"} 
	    ".bat" {$host.ui.rawui.foregroundColor = "Red"}
	    ".pdf" {$host.ui.rawui.foregroundColor = "Cyan"}
	    ".csv" {$host.ui.rawui.foregroundColor = "Cyan"}
	    ".txt" {$host.ui.rawui.foregroundColor = "Cyan"}
	    ".xml" {$host.ui.rawui.foregroundColor = "Cyan"}
	    ".docx" {$host.ui.rawui.foregroundColor = "Cyan"}
	    ".pptx" {$host.ui.rawui.foregroundColor = "Cyan"}
	    ".xlsx" {$host.ui.rawui.foregroundColor = "Cyan"}
	    ".log" {$host.ui.rawui.foregroundColor = "Cyan"}
	    ".png" {$host.ui.rawui.foregroundColor = "Magenta"}
	    ".jpg" {$host.ui.rawui.foregroundColor = "Magenta"}
	    ".gif" {$host.ui.rawui.foregroundColor = "Magenta"}
	    ".mp3" {$host.ui.rawui.foregroundColor = "Magenta"}
	    ".avi" {$host.ui.rawui.foregroundColor = "Magenta"}
	    ".wav" {$host.ui.rawui.foregroundColor = "Magenta"}
	    ".mp4" {$host.ui.rawui.foregroundColor = "Magenta"}
	    ".3GP" {$host.ui.rawui.foregroundColor = "Magenta"}
            Default {$host.ui.rawui.foregroundColor = $origFg} 
        } 
        if ($item.Mode.StartsWith("d")) {$host.ui.rawui.foregroundColor = "Gray"}
        $item 
    }  
    $host.ui.rawui.foregroundColor = $origFg 
}
function flla
{
    param ( $dir=".")
    ll $dir $true
}

function fla { ls -force }

#aliases
Set-Alias docs fdocs
Set-Alias code fcode
Set-Alias temp ftemp
Set-Alias proj fproj
Set-Alias IT fit
Set-Alias ll fll
Set-Alias lla flla
Set-Alias la fla