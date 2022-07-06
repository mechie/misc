# Place in $PROFILE.CurrentUserAllHosts
function Prompt {
    Write-Host (";") -NoNewLine -ForegroundColor $(If (($LastExitCode -eq $null -or $LastExitCode -eq 0) -and ($?)) {"Green"} else {"Red"})
    return " "
}
