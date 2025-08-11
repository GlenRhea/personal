Function New-Password { 
 
    [CmdletBinding()] 
    [OutputType([String])] 
 
     
    Param( 
 
        [int]$length=30, 
 
        [alias("U")] 
        [Switch]$Uppercase, 
 
        [alias("L")] 
        [Switch]$LowerCase, 
 
        [alias("N")] 
        [Switch]$Numeric, 
 
        [alias("S")] 
        [Switch]$Symbolic 
 
    ) 
 
    Begin {} 
 
    Process { 
         
        If ($Uppercase) {$CharPool += ([char[]](64..90))} 
        If ($LowerCase) {$CharPool += ([char[]](97..122))} 
        If ($Numeric) {$CharPool += ([char[]](48..57))} 
        If ($Symbolic) {$CharPool += ([char[]](33..47)) 
                       $CharPool += ([char[]](33..47))} 
         
        If ($CharPool -eq $null) { 
            Throw 'You must select at least one of the parameters "Uppercase" "LowerCase" "Numeric" or "Symbolic"' 
        } 
 
        [String]$Password =  (Get-Random -InputObject $CharPool -Count $length) -join '' 
 
    } 
     
    End { 
         
        return $Password 
     
    } 
}