<#
.SYNOPSIS
    Creates and configures a Cloudflare tunnel on Windows

.DESCRIPTION
    This script automates the complete setup of a Cloudflare tunnel, including:
    - Downloading cloudflared.exe
    - Authentication with Cloudflare
    - Tunnel creation and configuration
    - DNS record setup
    - Windows service installation

.PARAMETER TunnelName
    The name for the tunnel to create (default: "mytunnel")

.PARAMETER Hostname
    The public hostname for the tunnel (default: "mcp.wlmedia.com")

.PARAMETER LocalService
    The local service URL to expose (default: "http://localhost:8080")

.EXAMPLE
    .\create-cloudflare-tunnel.ps1
    Creates a tunnel with default settings

.EXAMPLE
    .\create-cloudflare-tunnel.ps1 -TunnelName "webserver" -Hostname "app.example.com" -LocalService "http://localhost:3000"
    Creates a tunnel with custom settings

.NOTES
    - Requires Administrator privileges
    - Requires active Cloudflare account
    - Domain must be managed by Cloudflare
    - The tunnel UUID is automatically captured during creation

.LINK
    https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="Name for the tunnel")]
    [string]$TunnelName = "mytunnel",
    
    [Parameter(HelpMessage="Public hostname for the tunnel")]
    [string]$Hostname = "mcp.wlmedia.com",
    
    [Parameter(HelpMessage="Local service URL to expose")]
    [string]$LocalService = "http://localhost:8080"
)

# Configuration Variables
$cfExe    = "$env:ProgramFiles\cloudflared\cloudflared.exe"
$cfDir    = "$env:USERPROFILE\.cloudflared"
$tunnel   = $TunnelName
$uuid     = $null  # Will be captured during tunnel creation

Write-Host "=== Cloudflare Tunnel Setup Script ===" -ForegroundColor Cyan
Write-Host "Tunnel Name: $tunnel" -ForegroundColor Green
Write-Host "Hostname: $Hostname" -ForegroundColor Green
Write-Host "Local Service: $LocalService" -ForegroundColor Green
Write-Host ""

# Step 1: Download cloudflared
Write-Host "Step 1: Checking for cloudflared..." -ForegroundColor Yellow
if (-Not (Test-Path $cfExe)) {
    Write-Host "Downloading cloudflared.exe..." -ForegroundColor Yellow
    
    # Create directory if it doesn't exist
    $cfParentDir = Split-Path $cfExe -Parent
    if (-Not (Test-Path $cfParentDir)) {
        New-Item -ItemType Directory -Path $cfParentDir -Force | Out-Null
    }
    
    try {
        $downloadUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $cfExe -UseBasicParsing
        Write-Host "✓ cloudflared.exe downloaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download cloudflared.exe: $_"
        exit 1
    }
} else {
    Write-Host "✓ cloudflared.exe already exists" -ForegroundColor Green
}

# Step 2: Authenticate with Cloudflare
Write-Host "`nStep 2: Authenticating with Cloudflare..." -ForegroundColor Yellow
Write-Host "This will open your browser for authentication." -ForegroundColor Cyan
try {
    & $cfExe login
    if ($LASTEXITCODE -ne 0) {
        throw "Authentication failed with exit code $LASTEXITCODE"
    }
    Write-Host "✓ Authentication completed" -ForegroundColor Green
}
catch {
    Write-Error "Authentication failed: $_"
    exit 1
}

# Step 3: Create tunnel
Write-Host "`nStep 3: Creating tunnel '$tunnel'..." -ForegroundColor Yellow
try {
    # Capture the output to parse the UUID
    $createOutput = & $cfExe tunnel create $tunnel 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Tunnel creation failed with exit code $LASTEXITCODE. Output: $createOutput"
    }
    
    # Parse the UUID from the output
    # Expected format: "Created tunnel <name> with id <uuid>"
    $uuidMatch = $createOutput | Select-String "Created tunnel .+ with id ([a-f0-9-]+)"
    if ($uuidMatch) {
        $uuid = $uuidMatch.Matches[0].Groups[1].Value
        Write-Host "✓ Tunnel '$tunnel' created successfully with UUID: $uuid" -ForegroundColor Green
    } else {
        # Fallback: try to find any UUID pattern in the output
        $uuidPattern = "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"
        $uuidMatch = $createOutput | Select-String $uuidPattern
        if ($uuidMatch) {
            $uuid = $uuidMatch.Matches[0].Value
            Write-Host "✓ Tunnel '$tunnel' created successfully with UUID: $uuid" -ForegroundColor Green
        } else {
            Write-Warning "Could not automatically extract tunnel UUID from output. Please check the tunnel creation manually."
            Write-Host "Command output: $createOutput" -ForegroundColor Gray
            throw "Failed to extract tunnel UUID"
        }
    }
}
catch {
    Write-Error "Tunnel creation failed: $_"
    exit 1
}

# Step 4: Generate config.yml
Write-Host "`nStep 4: Generating configuration file..." -ForegroundColor Yellow

# Validate UUID was captured
if (-not $uuid) {
    Write-Error "Tunnel UUID was not captured properly. Cannot continue with configuration."
    exit 1
}

# Create .cloudflared directory if it doesn't exist
if (-Not (Test-Path $cfDir)) {
    New-Item -ItemType Directory -Path $cfDir -Force | Out-Null
}

try {
    $configYml = @"
tunnel: $uuid
credentials-file: $cfDir\$uuid.json

ingress:
  - hostname: $Hostname
    service: $LocalService
  - service: http_status:404
"@
    $configYml | Set-Content -Path "$cfDir\config.yml" -Encoding UTF8
    Write-Host "✓ Configuration file created at $cfDir\config.yml" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create configuration file: $_"
    exit 1
}

# Step 5: Set DNS record
Write-Host "`nStep 5: Setting DNS record..." -ForegroundColor Yellow
try {
    & $cfExe tunnel route dns $tunnel $Hostname
    if ($LASTEXITCODE -ne 0) {
        throw "DNS setup failed with exit code $LASTEXITCODE"
    }
    Write-Host "✓ DNS record created for $Hostname" -ForegroundColor Green
}
catch {
    Write-Error "DNS setup failed: $_"
    Write-Host "You may need to manually create the DNS record in Cloudflare dashboard" -ForegroundColor Yellow
}

# Step 6: Install and start Windows service
Write-Host "`nStep 6: Installing Windows service..." -ForegroundColor Yellow

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Administrator privileges required for service installation. Please run PowerShell as Administrator."
    exit 1
}

try {
    # Install the service
    & $cfExe service install
    if ($LASTEXITCODE -ne 0) {
        throw "Service installation failed with exit code $LASTEXITCODE"
    }
    Write-Host "✓ cloudflared service installed" -ForegroundColor Green
    
    # Start the service
    Start-Service cloudflared
    Write-Host "✓ cloudflared service started" -ForegroundColor Green
    
    # Verify service status
    $service = Get-Service cloudflared -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Host "✓ Service is running successfully" -ForegroundColor Green
    } else {
        Write-Warning "Service may not be running properly. Check Event Viewer for details."
    }
}
catch {
    Write-Error "Service installation/startup failed: $_"
    Write-Host "You may need to install and start the service manually" -ForegroundColor Yellow
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Your tunnel should now be accessible at: https://$Hostname" -ForegroundColor Green
Write-Host "Tunnel UUID: $uuid" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify your local service is running on $LocalService" -ForegroundColor White
Write-Host "2. Test the tunnel by visiting https://$Hostname" -ForegroundColor White
Write-Host ""
Write-Host "To manage the service:" -ForegroundColor Yellow
Write-Host "  Start:   Start-Service cloudflared" -ForegroundColor White
Write-Host "  Stop:    Stop-Service cloudflared" -ForegroundColor White
Write-Host "  Status:  Get-Service cloudflared" -ForegroundColor White
