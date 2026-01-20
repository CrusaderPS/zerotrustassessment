# Helper script to run Docker Compose with proper setup
# Ensures the results directory exists before mounting

$ErrorActionPreference = 'Stop'

# Ensure results directory exists (required for Docker volume mount)
if (-not (Test-Path "results")) {
    Write-Host "Creating results directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "results" -Force | Out-Null
    Write-Host "Results directory created." -ForegroundColor Green
}

# Run docker-compose with the provided arguments
Write-Host "Starting Docker Compose..." -ForegroundColor Cyan
docker-compose $args
