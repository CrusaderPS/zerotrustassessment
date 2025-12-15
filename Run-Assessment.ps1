# Error handling
$ErrorActionPreference = 'Stop'

try {
    # Load the PFX certificate
    Write-Host 'Loading certificate...' -ForegroundColor Yellow
    $certPath = 'C:\ZeroTrustAssessment\MaesterAuth.pfx'
    if (-not (Test-Path $certPath)) {
        throw "Certificate file not found at: $certPath"
    }

    # Use certificate password directly (matching working Dockerfile pattern - no URL decoding needed)
    $certPassword = ConvertTo-SecureString -String $env:CERT_PASSWORD -AsPlainText -Force
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath, $certPassword, 'MachineKeySet,PersistKeySet')
    Write-Host 'Certificate loaded successfully' -ForegroundColor Green

    # Import certificate to CurrentUser store for Az module
    Write-Host 'Importing certificate to CurrentUser\My store...' -ForegroundColor Yellow
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "CurrentUser")
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Close()
    Write-Host 'Certificate imported to store successfully' -ForegroundColor Green

    # Import the ZeroTrustAssessment module
    Write-Host 'Importing ZeroTrustAssessment module...' -ForegroundColor Yellow
    $modulePath = 'C:\ZeroTrustAssessment\src\powershell\ZeroTrustAssessment.psd1'
    if (-not (Test-Path $modulePath)) {
        throw "Module file not found at: $modulePath"
    }
    Import-Module -Name $modulePath -Force
    Write-Host 'Module imported successfully' -ForegroundColor Green

    # Connect using certificate authentication (Direct MgGraph connection to avoid scope issues with app-only)
    Write-Host 'Connecting to Microsoft Graph...' -ForegroundColor Yellow
    Write-Host "  Application ID: $env:APPLICATION_ID" -ForegroundColor Gray
    Write-Host "  Tenant ID: $env:TENANT_ID" -ForegroundColor Gray

    # Connect to Graph
    Connect-MgGraph -ClientId $env:APPLICATION_ID -TenantId $env:TENANT_ID -Certificate $cert -NoWelcome
    Write-Host 'Connected to Microsoft Graph successfully' -ForegroundColor Green

    # Connect to Azure (Service Principal)
    Write-Host 'Connecting to Azure...' -ForegroundColor Yellow
    Connect-AzAccount -ServicePrincipal -ApplicationId $env:APPLICATION_ID -TenantId $env:TENANT_ID -CertificateThumbprint $cert.Thumbprint | Out-Null
    Write-Host 'Connected to Azure successfully' -ForegroundColor Green

    # Ensure results directory exists
    $resultsPath = 'C:\results'
    if (-not (Test-Path $resultsPath)) {
        New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null
    }

    # Check if HTML report already exists (assessment completed)
    $htmlReportPath = Join-Path $resultsPath "ZeroTrustAssessmentReport.html"
    $exportPath = Join-Path $resultsPath "zt-export"
    $hasExportData = (Test-Path $exportPath) -and ((Get-ChildItem $exportPath -ErrorAction SilentlyContinue).Count -gt 0)
    $hasHtmlReport = Test-Path $htmlReportPath

    # Determine if we should resume or start fresh
    $shouldResume = $false
    if ($hasExportData -and -not $hasHtmlReport) {
        Write-Host 'Found existing export data but no HTML report. Resuming assessment...' -ForegroundColor Yellow
        $shouldResume = $true
    }
    elseif ($hasHtmlReport) {
        Write-Host 'HTML report already exists. For a fresh assessment, delete the results folder first.' -ForegroundColor Yellow
        Write-Host "Report location: $htmlReportPath" -ForegroundColor Cyan
        exit 0
    }
    elseif ($hasExportData) {
        # In Docker/non-interactive mode, auto-clean if export data exists but no report
        Write-Host 'Cleaning existing export data for fresh assessment...' -ForegroundColor Yellow
        Remove-Item -Path $exportPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Run the assessment and output to results folder
    Write-Host 'Starting Zero Trust Assessment...' -ForegroundColor Yellow
    Write-Host "  Output path: $resultsPath" -ForegroundColor Gray
    if ($shouldResume) {
        Invoke-ZtAssessment -Path $resultsPath -DisableTelemetry -Resume
    }
    else {
        Invoke-ZtAssessment -Path $resultsPath -DisableTelemetry
    }
    Write-Host 'Assessment completed successfully!' -ForegroundColor Green
    Write-Host "Results are available in: $resultsPath" -ForegroundColor Cyan
    Write-Host "HTML Report: $htmlReportPath" -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner Exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    exit 1
}
