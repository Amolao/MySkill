[CmdletBinding()]
param(
    [ValidateRange(1,50)]
    [int]$Rounds = 5,
    [ValidateRange(0,300)]
    [int]$DelaySeconds = 2,
    [string]$Proxy,
    [string]$OutputCsv = (Join-Path $env:TEMP ("chatgpt-connectivity-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.csv')),
    [switch]$TestIPv6
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$Targets = @(
    @{ Domain = 'chatgpt.com'; Url = 'https://chatgpt.com/' },
    @{ Domain = 'auth.openai.com'; Url = 'https://auth.openai.com/' },
    @{ Domain = 'ws.chatgpt.com'; Url = 'https://ws.chatgpt.com/' },
    @{ Domain = 'oaistatic.com'; Url = 'https://oaistatic.com/' },
    @{ Domain = 'oaiusercontent.com'; Url = 'https://oaiusercontent.com/' },
    @{ Domain = 'desktop.chat.openai.com'; Url = 'https://desktop.chat.openai.com/' },
    @{ Domain = 'challenges.cloudflare.com'; Url = 'https://challenges.cloudflare.com/' }
)

function Protect-ProxyValue {
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return 'system/default' }
    return ($Value -replace '(?i)(https?|socks5h?|socks)://[^/@\s:]+:[^/@\s]+@', '$1://***:***@')
}

function Invoke-CurlProbe {
    param([string]$Url, [ValidateSet('4','6')][string]$IpVersion)

    $Args = @(
        '-sS',
        '-o', 'NUL',
        '-w', '%{http_code}|%{remote_ip}|%{time_namelookup}|%{time_connect}|%{time_appconnect}|%{time_total}',
        '--connect-timeout', '10',
        '--max-time', '20',
        '--http1.1',
        "-$IpVersion"
    )
    if ($Proxy) { $Args += @('--proxy', $Proxy) }
    $Args += $Url

    $Output = & curl.exe @Args 2>&1
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Raw = ($Output | Out-String).Trim()
    }
}

$Rows = [System.Collections.Generic.List[object]]::new()
$Versions = @('4')
if ($TestIPv6) { $Versions += '6' }

for ($Round = 1; $Round -le $Rounds; $Round++) {
    foreach ($Target in $Targets) {
        $DnsOk = $false
        $DnsAddresses = @()
        $DnsError = $null
        try {
            $Dns = Resolve-DnsName $Target.Domain -ErrorAction Stop |
                Where-Object { $_.Type -in @('A','AAAA') }
            $DnsAddresses = @($Dns | ForEach-Object IPAddress | Where-Object { $_ })
            $DnsOk = $DnsAddresses.Count -gt 0
        }
        catch { $DnsError = $_.Exception.Message }

        $TcpOk = $false
        try {
            $TcpOk = Test-NetConnection $Target.Domain -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
        }
        catch {}

        foreach ($Version in $Versions) {
            $Probe = Invoke-CurlProbe -Url $Target.Url -IpVersion $Version
            $Parts = $Probe.Raw -split '\|', 6
            $Rows.Add([pscustomobject]@{
                Timestamp = (Get-Date -Format o)
                Round = $Round
                Domain = $Target.Domain
                IPVersion = $Version
                Proxy = (Protect-ProxyValue $Proxy)
                DnsOk = $DnsOk
                DnsAddresses = ($DnsAddresses -join ';')
                DnsError = $DnsError
                Tcp443Ok = $TcpOk
                CurlExitCode = $Probe.ExitCode
                HttpCode = $(if ($Parts.Count -ge 1) { $Parts[0] } else { '' })
                RemoteIp = $(if ($Parts.Count -ge 2) { $Parts[1] } else { '' })
                NameLookupSeconds = $(if ($Parts.Count -ge 3) { $Parts[2] } else { '' })
                ConnectSeconds = $(if ($Parts.Count -ge 4) { $Parts[3] } else { '' })
                TlsSeconds = $(if ($Parts.Count -ge 5) { $Parts[4] } else { '' })
                TotalSeconds = $(if ($Parts.Count -ge 6) { $Parts[5] } else { '' })
                RawError = $(if ($Probe.ExitCode -ne 0) { $Probe.Raw } else { '' })
            })
        }
    }

    if ($Round -lt $Rounds -and $DelaySeconds -gt 0) {
        Start-Sleep -Seconds $DelaySeconds
    }
}

$Rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

$Summary = $Rows | Group-Object Domain,IPVersion | ForEach-Object {
    $Group = $_.Group
    [pscustomobject]@{
        Target = $_.Name
        Attempts = $Group.Count
        DnsFailures = ($Group | Where-Object { -not $_.DnsOk }).Count
        TcpFailures = ($Group | Where-Object { -not $_.Tcp443Ok }).Count
        CurlFailures = ($Group | Where-Object { $_.CurlExitCode -ne 0 }).Count
        HttpCodes = (($Group.HttpCode | Where-Object { $_ } | Sort-Object -Unique) -join ',')
        RemoteIps = (($Group.RemoteIp | Where-Object { $_ } | Sort-Object -Unique) -join ',')
    }
}

$Summary | Format-Table -AutoSize
Write-Host "CSV written to: $OutputCsv"
Write-Host 'HTTP 401/403/404 can still prove reachability. Focus on DNS, TCP, TLS, proxy, reset and timeout failures.'
