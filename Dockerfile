# Use Windows Server Core LTSC 2022 as base image
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Set environment variables for configuration
ENV APPLICATION_ID="58a6a0f9-c6cd-4d62-a926-d668ab305a2f"
ENV TENANT_ID="7570d255-ab35-4f21-b880-2e785a9e2cd4"
ENV CERT_PASSWORD="MySUp3rPwD2C0nn3cT@T3n@nT%25"

# Set working directory
WORKDIR C:\\ZeroTrustAssessment

# Install Chocolatey
RUN powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

# Install PowerShell 7 using Chocolatey
RUN choco install powershell-core -y --no-progress

# Install required PowerShell modules
RUN C:\Program` Files\PowerShell\7\pwsh.exe -Command "Install-Module -Name Az.Accounts -RequiredVersion 4.0.2 -Scope AllUsers -Force -AllowClobber"
RUN C:\Program` Files\PowerShell\7\pwsh.exe -Command "Install-Module -Name Microsoft.Graph.Authentication -RequiredVersion 2.32.0 -Scope AllUsers -Force -AllowClobber"
RUN C:\Program` Files\PowerShell\7\pwsh.exe -Command "Install-Module -Name Microsoft.Graph.Beta.Teams -RequiredVersion 2.32.0 -Scope AllUsers -Force -AllowClobber"
RUN C:\Program` Files\PowerShell\7\pwsh.exe -Command "Install-Module -Name PSFramework -RequiredVersion 1.13.419 -Scope AllUsers -Force -AllowClobber"

# Copy the certificate file
COPY MaesterAuth.pfx C:\\ZeroTrustAssessment\\MaesterAuth.pfx

# Copy the PowerShell module source
COPY src\\powershell C:\\ZeroTrustAssessment\\src\\powershell

# Copy the assessment runner script
COPY Run-Assessment.ps1 C:\\ZeroTrustAssessment\\Run-Assessment.ps1

# Create results directory
RUN powershell -Command "New-Item -ItemType Directory -Path C:\\results -Force | Out-Null"

# Set the entrypoint to run the assessment script using PowerShell 7
ENTRYPOINT ["C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-File", "C:\\ZeroTrustAssessment\\Run-Assessment.ps1"]
