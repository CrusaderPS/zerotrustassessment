# Use Windows Server Core LTSC 2022 as base image
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Set working directory
WORKDIR C:\\ZeroTrustAssessment

# Switch to administrator user
USER ContainerAdministrator

# Install PowerShell 7 and required components
RUN powershell -Command "Invoke-WebRequest -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi' -OutFile 'PowerShell.msi'"
RUN powershell -Command "Start-Process msiexec.exe -Wait -ArgumentList '/I PowerShell.msi /quiet'"
RUN powershell -Command "Remove-Item PowerShell.msi"

# Install Visual C++ Redistributable (Required for ZeroTrustAssessment)
RUN powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile 'vc_redist.x64.exe'"
RUN powershell -Command "Start-Process vc_redist.x64.exe -Wait -ArgumentList '/install /quiet /norestart'"
RUN powershell -Command "Remove-Item vc_redist.x64.exe"

RUN powershell -Command "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope AllUsers -Force"
RUN powershell -Command "Install-Module PowerShellGet -Scope AllUsers -Force"
RUN powershell -Command "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted"
RUN powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force"
RUN powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"

# Install required PowerShell modules
RUN powershell -Command "Install-Module -Name Az.Accounts -RequiredVersion 4.0.2 -Scope AllUsers -Force -AllowClobber"
RUN powershell -Command "Install-Module -Name Microsoft.Graph.Authentication -RequiredVersion 2.32.0 -Scope AllUsers -Force -AllowClobber"
RUN powershell -Command "Install-Module -Name Microsoft.Graph.Beta.Teams -RequiredVersion 2.32.0 -Scope AllUsers -Force -AllowClobber"
RUN powershell -Command "Install-Module -Name PSFramework -RequiredVersion 1.13.419 -Scope AllUsers -Force -AllowClobber"

# Copy the certificate file
COPY MaesterAuth.pfx C:\\ZeroTrustAssessment\\MaesterAuth.pfx

# Copy the PowerShell module source
COPY src\\powershell C:\\ZeroTrustAssessment\\src\\powershell

# Copy the assessment runner script
COPY Run-Assessment.ps1 C:\\ZeroTrustAssessment\\Run-Assessment.ps1

# Create results directory
RUN powershell -Command "New-Item -ItemType Directory -Path C:\\results -Force | Out-Null"

# Set environment variables for configuration
ENV APPLICATION_ID="58a6a0f9-c6cd-4d62-a926-d668ab305a2f"
ENV TENANT_ID="7570d255-ab35-4f21-b880-2e785a9e2cd4"
ENV CERT_PASSWORD="MySUp3rPwD2C0nn3cT@T3n@nT%25"

# Set the entrypoint to run the assessment script using PowerShell 7
ENTRYPOINT ["C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-ExecutionPolicy", "Bypass", "-File", "C:\\ZeroTrustAssessment\\Run-Assessment.ps1"]
