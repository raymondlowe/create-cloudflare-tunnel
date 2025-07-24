# Create Cloudflare Tunnel

A PowerShell script to automate the creation and setup of Cloudflare tunnels on Windows systems.

## Overview

This script automates the entire process of setting up a Cloudflare tunnel, from downloading the cloudflared binary to configuring it as a Windows service. It eliminates the manual steps typically required for tunnel creation and provides a streamlined way to expose local services through Cloudflare's network.

## Features

- Automatic download of the latest cloudflared binary
- Interactive authentication with Cloudflare
- Tunnel creation and configuration
- Automatic DNS record setup
- Windows service installation and startup
- Configurable hostname and local service settings

## Prerequisites

- Windows operating system
- PowerShell 5.1 or later
- Administrator privileges (required for service installation)
- Active Cloudflare account
- Domain managed by Cloudflare

## Quick Start

1. **Download the script:**
   ```powershell
   # Clone the repository or download create-cloudflare-tunnel.ps1
   ```

2. **Edit configuration variables:**
   Open `create-cloudflare-tunnel.ps1` and modify these variables at the top:
   ```powershell
   $tunnel   = "mytunnel"              # Change to your desired tunnel name
   $uuid     = "<TUNNEL-UUID>"         # Will be updated after tunnel creation
   ```

3. **Update the hostname in the config section:**
   ```powershell
   # In the ingress section, change:
   - hostname: mcp.wlmedia.com         # Change to your domain
     service: http://localhost:8080    # Change to your local service
   ```

4. **Run as Administrator:**
   ```powershell
   # Right-click PowerShell and "Run as Administrator"
   .\create-cloudflare-tunnel.ps1
   ```

## Configuration

### Main Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `$cfExe` | Path to cloudflared executable | `$env:ProgramFiles\cloudflared\cloudflared.exe` |
| `$cfDir` | Cloudflare configuration directory | `$env:USERPROFILE\.cloudflared` |
| `$tunnel` | Name of the tunnel to create | `mytunnel` |
| `$uuid` | Tunnel UUID (auto-generated) | `<TUNNEL-UUID>` |

### Ingress Rules

The script creates a configuration with ingress rules that define how traffic is routed:

```yaml
ingress:
  - hostname: your-domain.com    # Your public hostname
    service: http://localhost:8080  # Your local service
  - service: http_status:404     # Catch-all rule (required)
```

## What the Script Does

1. **Downloads cloudflared** - Fetches the latest Windows binary if not already present
2. **Authenticates** - Opens browser for Cloudflare login
3. **Creates tunnel** - Generates a new tunnel with your specified name
4. **Generates config** - Creates `config.yml` with your settings
5. **Sets DNS** - Creates DNS record pointing to your tunnel
6. **Installs service** - Sets up cloudflared as a Windows service
7. **Starts service** - Begins routing traffic through the tunnel

## After Running the Script

1. **Update the UUID** - After tunnel creation, copy the generated UUID and update the `$uuid` variable in the script
2. **Verify the service** - Check that the cloudflared service is running:
   ```powershell
   Get-Service cloudflared
   ```
3. **Test connectivity** - Visit your configured hostname to verify the tunnel is working

## Troubleshooting

### Common Issues

- **Permission Denied**: Ensure you're running PowerShell as Administrator
- **Download Fails**: Check your internet connection and firewall settings
- **Authentication Issues**: Ensure you have a valid Cloudflare account and the domain is added to your account
- **Service Won't Start**: Check the config.yml file for syntax errors

### Log Files

Cloudflared logs can be found in:
- Windows Event Viewer (Application logs)
- `%USERPROFILE%\.cloudflared\` directory

### Manual Commands

If you need to manage the tunnel manually:

```powershell
# List tunnels
cloudflared tunnel list

# Delete a tunnel
cloudflared tunnel delete <tunnel-name>

# Stop the service
Stop-Service cloudflared

# Uninstall the service
cloudflared service uninstall
```

## Security Considerations

- The script downloads executables from the internet - ensure you trust the source
- Tunnel credentials are stored in `%USERPROFILE%\.cloudflared\`
- The service runs with elevated privileges

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Resources

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [cloudflared GitHub Repository](https://github.com/cloudflare/cloudflared)
- [Cloudflare Dashboard](https://dash.cloudflare.com/)