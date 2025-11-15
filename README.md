# n8n-ngrok tunnel Setup Script

A very simple PowerShell script that automates the process of starting n8n with ngrok tunneling.

## Prerequisites

- ngrok installed and authenticated
- Node.js and npx installed
- n8n installed globally or available via npx

## Usage

1. Start ngrok in a terminal:
   ```
   ngrok http 5678
   ```

2. Run the PowerShell script in another terminal:
   ```
   .\start.ps1
   ```

3. When prompted for the ngrok API URL, press Enter to use the default (`http://localhost:4040/api/tunnels`)

## What it does

The script will:
- Verify that ngrok is running
- Fetch the public HTTPS URL from ngrok's local API
- Set the `WEBHOOK_URL` environment variable automatically
- Start n8n using `npx n8n`

## Notes

- Only runs in windows!
- The script expects ngrok to already be running before execution
- ngrok will continue running after the script terminates
- Press Ctrl+C to stop n8n when finished