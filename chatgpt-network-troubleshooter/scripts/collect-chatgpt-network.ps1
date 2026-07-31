[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $env:TEMP ("chatgpt-network-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [string]$HostsPath = (Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'),
    [switch]$SkipReachability
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

function Write-Section {
    param([string]$Path, [string]$Title)
    Add-Content -Path $Path -Value ("`r`n===== {0} =====" -f $Title) -Encoding UTF8
}

function Invoke-Capture {
    param([string]$Path, [string]$Title, [scriptblock]$Script)
    Write-Section -Path $Path -Title $Title
    try {
        & $Script 2>&1 | Out-String -Width 240 | Add-Content -Path $Path -Encoding UTF8
    }
    catch {
        ("ERROR: {0}" -f $_.Exception.Message) | Add-Content -Path $Path -Encoding UTF8
    }
}

function Protect-ProxyValue {
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }
    $Masked = $Value -replace '(?i)(https?|socks5h?|socks)://[^/@\s:]+:[^/@\s]+@', '$1://***:***@'
    return $Masked
}

function Get-TlsCertificateSummary {
    param([Parameter(Mandatory)][string]$HostName, [int]$Port = 443)
    $Tcp = $null
    $Ssl = $null
    try {
        $Tcp = [System.Net.Sockets.TcpClient]::new()
        $Async = $Tcp.ConnectAsync($HostName, $Port)
        if (-not $Async.Wait(10000)) { throw 'TCP connect timeout' }
        $Ssl = [System.Net.Security.SslStream]::new($Tcp.GetStream(), $false, { $true })
        $Ssl.AuthenticateAsClient($HostName)
        $Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Ssl.RemoteCertificate)
        [pscustomobject]@{
            Host = $HostName
            Protocol = $Ssl.SslProtocol
            Subject = $Cert.Subject
            Issuer = $Cert.Issuer
            NotBefore = $Cert.NotBefore
            NotAfter = $Cert.NotAfter
            Thumbprint = $Cert.Thumbprint
        }
    }
    catch {
        [pscustomobject]@{ Host = $HostName; Error = $_.Exception.Message }
    }
    finally {
        if ($Ssl) { $Ssl.Dispose() }
        if ($Tcp) { $Tcp.Dispose() }
    }
}

$Summary = Join-Path $OutputDirectory 'summary.txt'
$Network = Join-Path $OutputDirectory 'proxy-routing-dns.txt'
$Processes = Join-Path $OutputDirectory 'processes-and-listeners.txt'
$Reachability = Join-Path $OutputDirectory 'openai-reachability.txt'

"Collected: $(Get-Date -Format o)" | Set-Content -Path $Summary -Encoding UTF8
"Computer: $env:COMPUTERNAME" | Add-Content -Path $Summary -Encoding UTF8
"User: $env:USERNAME" | Add-Content -Path $Summary -Encoding UTF8
"PowerShell: $($PSVersionTable.PSVersion)" | Add-Content -Path $Summary -Encoding UTF8
"Output: $OutputDirectory" | Add-Content -Path $Summary -Encoding UTF8

Invoke-Capture -Path $Summary -Title 'Windows version and clock' -Script {
    Get-CimInstance Win32_OperatingSystem |
        Select-Object Caption,Version,BuildNumber,OSArchitecture,LastBootUpTime,LocalDateTime
}

Invoke-Capture -Path $Network -Title 'Proxy environment variables (credentials masked)' -Script {
    Get-ChildItem Env: |
        Where-Object Name -Match '^(HTTP|HTTPS|ALL|NO)_PROXY$' |
        Sort-Object Name |
        ForEach-Object {
            [pscustomobject]@{ Name = $_.Name; Value = (Protect-ProxyValue $_.Value) }
        }
}

Invoke-Capture -Path $Network -Title 'Current-user Internet Settings' -Script {
    Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' |
        Select-Object ProxyEnable,ProxyServer,AutoConfigURL,ProxyOverride,AutoDetect
}

Invoke-Capture -Path $Network -Title 'WinHTTP proxy' -Script { netsh winhttp show proxy }
Invoke-Capture -Path $Network -Title 'Active adapters' -Script {
    Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object Status -eq 'Up' |
        Select-Object Name,InterfaceDescription,ifIndex,MacAddress,LinkSpeed
}
Invoke-Capture -Path $Network -Title 'IP configuration' -Script {
    Get-NetIPConfiguration -ErrorAction SilentlyContinue |
        Select-Object InterfaceAlias,InterfaceIndex,IPv4Address,IPv6Address,IPv4DefaultGateway,IPv6DefaultGateway,DNSServer
}
Invoke-Capture -Path $Network -Title 'DNS servers' -Script { Get-DnsClientServerAddress -ErrorAction SilentlyContinue }
Invoke-Capture -Path $Network -Title 'Default routes' -Script {
    Get-NetRoute -ErrorAction SilentlyContinue |
        Where-Object DestinationPrefix -in @('0.0.0.0/0','::/0') |
        Sort-Object AddressFamily,RouteMetric,InterfaceMetric |
        Select-Object AddressFamily,DestinationPrefix,NextHop,InterfaceAlias,RouteMetric,InterfaceMetric,State
}

Invoke-Capture -Path $Processes -Title 'ChatGPT/OpenAI processes' -Script {
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -match 'ChatGPT|OpenAI' } |
        Select-Object Id,ProcessName,Path,StartTime
}

Invoke-Capture -Path $Processes -Title 'ChatGPT/OpenAI Appx packages' -Script {
    Get-AppxPackage -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'ChatGPT|OpenAI' } |
        Select-Object Name,Version,InstallLocation,PackageFamilyName
}

Invoke-Capture -Path $Processes -Title 'Loopback listening ports and owning processes' -Script {
    $Connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalAddress -in @('127.0.0.1','::1','0.0.0.0','::') }
    foreach ($Connection in ($Connections | Sort-Object LocalPort)) {
        $Process = Get-Process -Id $Connection.OwningProcess -ErrorAction SilentlyContinue
        [pscustomobject]@{
            LocalAddress = $Connection.LocalAddress
            LocalPort = $Connection.LocalPort
            ProcessId = $Connection.OwningProcess
            ProcessName = $Process.ProcessName
            ProcessPath = $Process.Path
        }
    }
}

Invoke-Capture -Path $Processes -Title 'Network-like adapters and services (inventory only)' -Script {
    Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'tun|tap|vpn|proxy|wireguard|wintun' -or $_.InterfaceDescription -match 'tun|tap|vpn|proxy|wireguard|wintun' } |
        Select-Object Name,InterfaceDescription,Status,ifIndex
}

Write-Section -Path $Summary -Title 'Relevant hosts entries'
if (Test-Path $HostsPath) {
    $Matches = Select-String -Path $HostsPath -Pattern 'openai|chatgpt|oaistatic|oaiusercontent|cloudflare|auth0|workos' -CaseSensitive:$false
    if ($Matches) {
        $Matches | ForEach-Object { "Line $($_.LineNumber): $($_.Line.Trim())" } |
            Add-Content -Path $Summary -Encoding UTF8
    } else {
        'No relevant hosts entries found.' | Add-Content -Path $Summary -Encoding UTF8
    }
} else {
    "Hosts file not found: $HostsPath" | Add-Content -Path $Summary -Encoding UTF8
}

if (-not $SkipReachability) {
    $Domains = @(
        'chatgpt.com',
        'auth.openai.com',
        'ws.chatgpt.com',
        'oaistatic.com',
        'oaiusercontent.com',
        'desktop.chat.openai.com',
        'challenges.cloudflare.com'
    )

    foreach ($Domain in $Domains) {
        Invoke-Capture -Path $Reachability -Title "DNS $Domain" -Script {
            Resolve-DnsName $Domain -ErrorAction Continue |
                Select-Object Name,Type,IPAddress,NameHost
        }
        Invoke-Capture -Path $Reachability -Title "TCP 443 $Domain" -Script {
            Test-NetConnection $Domain -Port 443 -InformationLevel Detailed
        }
        Invoke-Capture -Path $Reachability -Title "TLS certificate $Domain" -Script {
            Get-TlsCertificateSummary -HostName $Domain
        }
    }
}

Write-Host "Diagnostics collected in: $OutputDirectory"
Write-Host 'Review files before sharing. They may contain local paths, IP addresses, certificate details and process metadata.'
