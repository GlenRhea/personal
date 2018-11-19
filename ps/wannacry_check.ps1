# Check for hotfixes which patch the ms17-010 vulnerability. 
# # Example output: 
# PS C:\> .\checkfix.ps1 
# Found HotFix: KB4015550 

$hotfixes = "KB4012212", "KB4012212", "KB4012213", "KB4012213", "KB4012214", "KB4012215", "KB4012215", "KB4012216", "KB4012216", "KB4012217", "KB4012219", "KB4012220", "KB4012598", "KB4012598", "KB4012598", "KB4012598", "KB4012598", "KB4012606", "KB4013198", "KB4013429", "KB4013429", "KB4015217", "KB4015438", "KB4015549", "KB4015550", "KB4015550", "KB4015551", "KB4015553", "KB4015554", "KB4016635", "KB4019215", "KB4019215", "KB4019216", "KB4019264", "KB4019264", "KB4019472" 

$hotfix = Get-HotFix | Where-Object {$hotfixes -contains $_.HotfixID} | Select-Object -property "HotFixID" 

if (Get-HotFix | Where-Object {$hotfixes -contains $_.HotfixID}) { "Found HotFix: " + $hotfix.HotFixID } 
else { "Did not Find HotFix" }