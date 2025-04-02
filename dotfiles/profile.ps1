# Place in $PROFILE.CurrentUserAllHosts
function Prompt {
    Write-Host (";") -NoNewLine -ForegroundColor $(If (($LastExitCode -eq $null -or $LastExitCode -eq 0) -and ($?)) {"Green"} else {"Red"})

    [bool] $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    [string] $title = If ($isAdmin) {"! "} else {""};
    $title += "$($executionContext.SessionState.Path.CurrentLocation)".
        Replace("${HOME}", "~").
        Replace('\', '/');
    $Host.UI.RawUI.WindowTitle = $title;

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
