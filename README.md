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

2. **Run the script with your desired settings:**
   Open an Administrator PowerShell window and run:
   ```powershell
   .\create-cloudflare-tunnel.ps1 -TunnelName "mytunnel" -Hostname "your.domain.com" -LocalService "http://localhost:8080"
   ```
   - `-TunnelName` sets the name for your tunnel (default: `mytunnel`)
   - `-Hostname` sets the public hostname (default: `mcp.wlmedia.com`)
   - `-LocalService` sets the local service URL to expose (default: `http://localhost:8080`)

   Example:
   ```powershell
   .\create-cloudflare-tunnel.ps1 -TunnelName "webserver" -Hostname "app.example.com" -LocalService "http://localhost:3000"
   ```

3. **Follow the prompts:**
   The script will:
   - Download cloudflared if needed
   - Authenticate with Cloudflare
   - Create the tunnel
   - Generate the config file
   - Set up the DNS record
   - Install and start the Windows service

4. **Test the tunnel:**
   See the [Testing the Tunnel](#testing-the-tunnel) section below.

## Configuration

All configuration is handled via command-line parameters. You do **not** need to edit variables in the script.

- To change the tunnel name, hostname, or local service, simply pass the appropriate arguments when running the script.
- The script will generate the correct config file and manage all required settings automatically.

## What the Script Does

1. **Downloads cloudflared** - Fetches the latest Windows binary if not already present
2. **Authenticates** - Opens browser for Cloudflare login
3. **Creates tunnel** - Generates a new tunnel with your specified name
4. **Generates config** - Creates `config.yml` with your settings
5. **Sets DNS** - Creates DNS record pointing to your tunnel
6. **Installs service** - Sets up cloudflared as a Windows service
7. **Starts service** - Begins routing traffic through the tunnel

## Testing the Tunnel

A simple test server is included to help verify your tunnel setup:

1. Start the test server:
   ```powershell
   python test-server.py
   ```
   This will start a web server on `localhost:8080` that responds with a Hello World page.

2. Visit your public tunnel URL (e.g. `https://mcp.wlmedia.com`) in your browser. You should see the Hello World page from the test server.

3. Stop the test server with `Ctrl+C` when done.

## Test Summary

See [CLOUDFLARE_TUNNEL_TEST_SUMMARY.md](CLOUDFLARE_TUNNEL_TEST_SUMMARY.md) for a detailed log of a successful end-to-end test.

## Troubleshooting

### Common Issues

- **Permission Denied**: Ensure you're running PowerShell as Administrator
- **Download Fails**: Check your internet connection and firewall settings
- **Authentication Issues**: Ensure you have a valid Cloudflare account and the domain is added to your account
- **Service Won't Start**: Check the config.yml file for syntax errors

### Config Formatting

- If the tunnel service does not connect, check your `.cloudflared/config.yml` for line wrapping or formatting issues. The file should not have extra line breaks in the tunnel UUID or credentials-file path.
- If you see errors about the service not stopping, you may need to kill the `cloudflared` process manually using Task Manager or `Stop-Process` in PowerShell.

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