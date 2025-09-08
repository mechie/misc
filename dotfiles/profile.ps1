# Place in $PROFILE.CurrentUserAllHosts
function Prompt {
    Write-Host (";") -NoNewLine -ForegroundColor $(If (($LastExitCode -eq $null -or $LastExitCode -eq 0) -and ($?)) {"Green"} else {"Red"})

    [bool] $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    [string] $title = If ($isAdmin) {"! "} else {""};
    $title += "$($executionContext.SessionState.Path.CurrentLocation)".
        Replace("${HOME}", "~").
        Replace('\', '/').
        Replace('~/repositories/', '~/r/').
        Replace('~/r/personal/', '~/r/p/');
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

function AwsLogin([string]$ProfileName) {
    function Read-AwsConfig([string]$ConfigPath) {
        if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
            if ($env:AWS_CONFIG_FILE) {
                $ConfigPath = $env:AWS_CONFIG_FILE
            } else {
                $ConfigPath = Join-Path -Path $HOME -ChildPath ".aws/config"
            }
        }

        $sectionToKeys = @{}
        if (Test-Path -Path $ConfigPath) {
            $currentSectionName = $null
            foreach ($rawLine in (Get-Content -Path $ConfigPath)) {
                $line = $rawLine.Trim()
                if ($line -match '^\s*[#;]') {}
                elseif ($line -match '^\[(?<name>[^\]]+)\]') {
                    $currentSectionName = $Matches['name'].Trim()
                    $sectionToKeys[$currentSectionName] = @{}
                }
                elseif ($currentSectionName -and $line -match '^(?<key>[^=]+)=(?<value>.*)$') {
                    $key = $Matches['key'].Trim()
                    $value = $Matches['value'].Trim()
                    $sectionToKeys[$currentSectionName][$key] = $value
                }
            }
        }

        return $sectionToKeys
    }

    function Get-SsoContextForProfile([string]$ResolvedProfileName, $ConfigMap) {
        $sectionName = ($ResolvedProfileName -eq 'default') ? 'default' : "profile $ResolvedProfileName"
        if (-not $ConfigMap.ContainsKey($sectionName)) {
            return $null
        }

        $profileKVs = $ConfigMap[$sectionName]
        $startUrl = $profileKVs['sso_start_url']
        $ssoRegion = $profileKVs['sso_region']

        if (-not $startUrl -and $profileKVs.ContainsKey('sso_session')) {
            $sessionRef = $profileKVs['sso_session']
            $sessionSection = "sso-session $sessionRef"
            if ($ConfigMap.ContainsKey($sessionSection)) {
                $startUrl = $ConfigMap[$sessionSection]['sso_start_url']
                $ssoRegion = $ConfigMap[$sessionSection]['sso_region']
            }
        }

        if ($startUrl) {
            $startUrl = $startUrl.TrimEnd('/')
        }

        if (-not $startUrl -or -not $ssoRegion) {
            return $null
        }

        return [PSCustomObject]@{
            StartUrl = $startUrl
            Region   = $ssoRegion
        }
    }

    function Test-HasValidSsoDeviceToken ([string]$SsoStartUrl, [string]$SsoRegion, [int]$SkewSeconds){
        if ([string]::IsNullOrWhiteSpace($SsoStartUrl) -or [string]::IsNullOrWhiteSpace($SsoRegion)) {
            return $false
        }

        $cacheDirectory = Join-Path -Path $HOME -ChildPath ".aws/sso/cache"
        if (-not (Test-Path -Path $cacheDirectory)) {
            return $false
        }

        $mustBeValidAfter = [DateTime]::UtcNow.AddSeconds($SkewSeconds)
        foreach ($file in (Get-ChildItem -Path $cacheDirectory -Filter "*.json" -ErrorAction SilentlyContinue)) {
            $json = $null
            try { $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json } catch { continue }

            $jsonStartUrl = $null
            if ($json.PSObject.Properties.Name -contains 'startUrl') {
                $jsonStartUrl = $json.startUrl
            }
            if ($jsonStartUrl) {
                $jsonStartUrl = $jsonStartUrl.TrimEnd('/')
            }
            if (
                ($jsonStartUrl -ne $SsoStartUrl) -or
                ($json.PSObject.Properties.Name -notcontains 'region') -or
                ($json.region -ne $SsoRegion) -or
                ($json.PSObject.Properties.Name -notcontains 'expiresAt')
            ) { continue }

            $expiresAt = $null
            try { $expiresAt = [DateTime]::Parse($json.expiresAt).ToUniversalTime() } catch { continue }

            if ($expiresAt -gt $mustBeValidAfter) {
                return $true
            }
        }

        return $false
    }

    if ([string]::IsNullOrWhitespace("${ProfileName}")) {
        if ([string]::IsNullOrWhitespace("${env:AWS_PROFILE}")) {
            Write-Host "; aws configure list-profiles"
            aws configure list-profiles
            Write-Error "aws-login must be called with a profile name from the above"
            return
        }
        else {
            $ProfileName = "${env:AWS_PROFILE}"
        }
    }

    $env:AWS_PROFILE = "${ProfileName}"
    $ssoContext = $(Get-SsoContextForProfile -ResolvedProfileName $ProfileName -ConfigMap $(Read-AwsConfig))
    if (-not $ssoContext) {
        Write-Host "Profile '${ProfileName}' not SSO-backed, skipping 'aws sso login'"
        return
    }

    if (Test-HasValidSsoDeviceToken -SsoStartUrl $ssoContext.StartUrl `
                                    -SsoRegion $ssoContext.Region `
                                    -SkewSeconds 3600) {
        Write-Host "Using cached SSO for '${ProfileName}'"
        return
    }

    aws sso login
}

Set-Alias -Name which -Value GetCommandPath
Set-Alias -Name aws-login -Value AwsLogin
