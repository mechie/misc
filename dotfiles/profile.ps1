# Place in $PROFILE.CurrentUserAllHosts
function Prompt {
    Write-Host (";") -NoNewLine -ForegroundColor $(If (($LastExitCode -eq $null -or $LastExitCode -eq 0) -and ($?)) {"Green"} else {"Red"})
    return " "
}

function GetCommandPath([string]$Command) {
    try {
        (Get-Command "${Command}").Path;
    }
    catch {
        Write-Error("Could not Get-Command. It may not be reachable, or your shell is misbehaving");
    }
}

Set-Alias -Name which -Value GetCommandPath
