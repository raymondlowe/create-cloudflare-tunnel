# Variables
$cfExe    = "$env:ProgramFiles\cloudflared\cloudflared.exe"
$cfDir    = "$env:USERPROFILE\.cloudflared"
$tunnel   = "mytunnel"
$uuid     = "<TUNNEL-UUID>"

# 1. Download cloudflared
if (-Not (Test-Path $cfExe)) {
    Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $cfExe
}

# 2. Authenticate (run interactively)
& $cfExe login

# 3. Create tunnel (run interactively)
& $cfExe tunnel create $tunnel

# 4. Generate config.yml (update $uuid)
$configYml = @"
tunnel: $uuid
credentials-file: $cfDir\$uuid.json

ingress:
  - hostname: mcp.wlmedia.com
    service: http://localhost:8080
  - service: http_status:404
"@
$configYml | Set-Content -Path "$cfDir\config.yml"

# 5. Set DNS
& $cfExe tunnel route dns $tunnel mcp.wlmedia.com

# 6. Install and start as service
& $cfExe service install
Start-Service cloudflared
