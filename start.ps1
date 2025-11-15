# Define the port n8n runs on (default is 5678)
$n8n_port = 5678

# Prompt for ngrok API URL with default value
$default_ngrok_api = "http://localhost:4040/api/tunnels"
$ngrok_api_url = Read-Host "Enter ngrok API URL (press Enter for default: $default_ngrok_api)"

if ([string]::IsNullOrWhiteSpace($ngrok_api_url)) {
    $ngrok_api_url = $default_ngrok_api
}

Write-Host "`nUsing ngrok API URL: $ngrok_api_url`n" -ForegroundColor Cyan

# Function to verify ngrok API URL
function Test-NgrokApi {
    param([string]$ApiUrl)
    
    try {
        Write-Host "Verifying ngrok API URL accessibility..." -ForegroundColor Yellow
        Write-Host "Attempting to connect to: $ApiUrl" -ForegroundColor Gray
        
        $response = Invoke-RestMethod -Uri $ApiUrl -TimeoutSec 10 -ErrorAction Stop
        
        Write-Host "Response received. Type: $($response.GetType().Name)" -ForegroundColor Gray
        
        if ($response.tunnels) {
            Write-Host "Success: ngrok API URL verified successfully!" -ForegroundColor Green
            Write-Host "Found $($response.tunnels.Count) tunnel(s)" -ForegroundColor Gray
            return $true
        } else {
            Write-Warning "API responded but no tunnel data structure found."
            Write-Host "Response content: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
            return $false
        }
    }
    catch {
        Write-Error "Failed to verify ngrok API URL: $_"
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Error type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        return $false
    }
}

# --- Verify ngrok is already running ---
Write-Host "Checking if ngrok is already running..." -ForegroundColor Cyan

$api_verified = Test-NgrokApi -ApiUrl $ngrok_api_url

if (-not $api_verified) {
    Write-Error "`nCould not connect to ngrok API."
    Write-Host "Please ensure ngrok is already running with: ngrok http $n8n_port" -ForegroundColor Yellow
    exit 1
}

try {
    # --- Fetch ngrok tunnel info ---
    Write-Host "`nFetching ngrok tunnel information..." -ForegroundColor Cyan
    $tunnels_json = Invoke-RestMethod -Uri $ngrok_api_url -ErrorAction Stop
    
    # Extract the public HTTPS URL
    $ngrok_url = ($tunnels_json.tunnels | Where-Object { $_.proto -eq 'https' }).public_url
    
    if (-not $ngrok_url) {
        throw "Could not find HTTPS ngrok URL in API response. Ensure ngrok is tunneling port $n8n_port"
    }
    
    Write-Host "Success: Ngrok HTTPS URL obtained: $ngrok_url" -ForegroundColor Green
    
    # --- Set the WEBHOOK_URL environment variable (PowerShell equivalent of 'set') ---
    $env:WEBHOOK_URL = $ngrok_url
    Write-Host "Success: WEBHOOK_URL environment variable set to: $ngrok_url" -ForegroundColor Green
    Write-Host "(Equivalent to: set WEBHOOK_URL=$ngrok_url)`n" -ForegroundColor Gray
    
    # --- Start n8n using npx ---
    Write-Host "Starting n8n with: npx n8n" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop n8n.`n" -ForegroundColor Yellow
    
    # Start n8n using npx (this blocks until n8n exits)
    npx n8n
}
catch {
    Write-Error "`nAn error occurred: $_"
    exit 1
}
finally {
    Write-Host "`nScript terminated." -ForegroundColor Cyan
    Write-Host "Note: ngrok is still running. Stop it manually if needed." -ForegroundColor Yellow
}