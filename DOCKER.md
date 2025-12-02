# Docker Usage for Zero Trust Assessment

This Dockerfile allows you to run the Zero Trust Assessment in a Windows container using certificate-based authentication.

## Prerequisites

- Docker Desktop with Windows containers enabled
- The `MaesterAuth.pfx` certificate file must be present in the repository root
- Windows Server Core LTSC 2022 container support

## Building the Docker Image

```powershell
docker build -t zerotrust-assessment:latest .
```

## Running the Container

### Using Docker Run

To run the assessment and export results to a local folder:

**PowerShell:**
```powershell
docker run --rm -v ${PWD}/results:C:/results zerotrust-assessment:latest
```

**Windows Command Prompt:**
```cmd
docker run --rm -v %CD%\results:C:/results zerotrust-assessment:latest
```

### Using Docker Compose

Alternatively, you can use docker-compose for easier management:

```powershell
docker-compose up
```

This will:
- Build the image if it doesn't exist
- Run the container
- Mount the `results` folder to your local machine
- Remove the container after execution

To rebuild the image:
```powershell
docker-compose build
```

## Environment Variables

The following environment variables are set in the Dockerfile but can be overridden:

- `APPLICATION_ID`: The Azure AD Application (Client) ID
- `TENANT_ID`: The Azure AD Tenant ID  
- `CERT_PASSWORD`: The password for the PFX certificate

To override environment variables:

```powershell
docker run --rm -v ${PWD}/results:C:\results -e APPLICATION_ID="your-app-id" -e TENANT_ID="your-tenant-id" -e CERT_PASSWORD="your-password" zerotrust-assessment:latest
```

## Results

The assessment results will be exported to the `results` folder on your local machine, which is mounted as a volume in the container. The results include:

- `ZeroTrustAssessmentReport.html` - HTML report
- `zt-export/` - Exported tenant data and JSON results
- `log/` - Log files (if ExportLog is enabled)

## Troubleshooting

### Certificate Issues

If you encounter certificate loading errors, verify:
1. The `MaesterAuth.pfx` file exists in the repository root
2. The `CERT_PASSWORD` environment variable matches the certificate password
3. The certificate is valid and not expired

### Module Installation Issues

If PowerShell modules fail to install, the container build will fail. Ensure:
1. Internet connectivity during build
2. PowerShell Gallery is accessible
3. Sufficient disk space in the container

### Connection Issues

If authentication fails:
1. Verify the `APPLICATION_ID` and `TENANT_ID` are correct
2. Ensure the certificate is registered with the Azure AD application
3. Check that the application has the required Microsoft Graph API permissions
