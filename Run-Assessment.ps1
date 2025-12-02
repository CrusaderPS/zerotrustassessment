# Error handling
$ErrorActionPreference = 'Stop'

try {
    # Load the PFX certificate
    Write-Host 'Loading certificate...' -ForegroundColor Yellow
    $certPath = 'C:\ZeroTrustAssessment\MaesterAuth.pfx'
    if (-not (Test-Path $certPath)) {
        throw "Certificate file not found at: $certPath"
    }
    # Decode URL-encoded password if needed
    $passwordPlain = [System.Uri]::UnescapeDataString($env:CERT_PASSWORD)
    $certPassword = ConvertTo-SecureString -String $passwordPlain -AsPlainText -Force
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath, $certPassword)
    Write-Host 'Certificate loaded successfully' -ForegroundColor Green

    # Import the ZeroTrustAssessment module
    Write-Host 'Importing ZeroTrustAssessment module...' -ForegroundColor Yellow
    $modulePath = 'C:\ZeroTrustAssessment\src\powershell\ZeroTrustAssessment.psd1'
    if (-not (Test-Path $modulePath)) {
        throw "Module file not found at: $modulePath"
    }
    Import-Module -Name $modulePath -Force
    Write-Host 'Module imported successfully' -ForegroundColor Green

    # Connect using certificate authentication
    Write-Host 'Connecting to Microsoft Graph...' -ForegroundColor Yellow
    Write-Host "  Application ID: $env:APPLICATION_ID" -ForegroundColor Gray
    Write-Host "  Tenant ID: $env:TENANT_ID" -ForegroundColor Gray
    Connect-ZtAssessment -ClientId $env:APPLICATION_ID -TenantId $env:TENANT_ID -Certificate $cert
    Write-Host 'Connected successfully' -ForegroundColor Green

    # Ensure results directory exists
    $resultsPath = 'C:\results'
    if (-not (Test-Path $resultsPath)) {
        New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null
    }

    # Run the assessment and output to results folder
    Write-Host 'Starting Zero Trust Assessment...' -ForegroundColor Yellow
    Write-Host "  Output path: $resultsPath" -ForegroundColor Gray
    Invoke-ZtAssessment -Path $resultsPath -DisableTelemetry
    Write-Host 'Assessment completed successfully!' -ForegroundColor Green
    Write-Host "Results are available in: $resultsPath" -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
