<#
.SYNOPSIS
   Helper method to connect to Microsoft Graph using Connect-MgGraph with the required scopes.

.DESCRIPTION
   Use this cmdlet to connect to Microsoft Graph using Connect-MgGraph.

   This command is completely optional if you are already connected to Microsoft Graph and other services using Connect-MgGraph with the required scopes.

   ```
   Connect-MgGraph -Scopes (Get-ZtGraphScope)
   ```

.EXAMPLE
   Connect-ZtAssessment

   Connects to Microsoft Graph using Connect-MgGraph with the required scopes.


.EXAMPLE
   Connect-ZtAssessment -UseDeviceCode

   Connects to Microsoft Graph and Azure using the device code flow. This will open a browser window to prompt for authentication.

.EXAMPLE
    Connect-ZtAssessment -SkipAzureConnection

    Connects to Microsoft Graph only, skipping the Azure connection. The tests that require Azure connectivity will be skipped.

.EXAMPLE
    Connect-ZtAssessment -ClientId "your-app-id" -TenantId "your-tenant-id" -CertificateThumbprint "certificate-thumbprint"

    Connects to Microsoft Graph using certificate authentication with an app registration. The certificate must be installed in the CurrentUser or LocalMachine certificate store.
#>

function Connect-ZtAssessment
{
    [CmdletBinding()]
    param(
        # If specified, the cmdlet will use the device code flow to authenticate to Graph and Azure.
        # This will open a browser window to prompt for authentication and is useful for non-interactive sessions and on Windows when SSO is not desired.
        [switch] $UseDeviceCode,

        # The environment to connect to. Default is Global.
        [ValidateSet('China', 'Germany', 'Global', 'USGov', 'USGovDoD')]
        [string]$Environment = 'Global',

        # Uses Graph Powershell's cached authentication tokens.
        [switch]$UseTokenCache,

        # The tenant ID to connect to. If not specified, the default tenant will be used.
        [string]$TenantId,

        # If specified, connects using a custom application identity. See https://learn.microsoft.com/powershell/microsoftgraph/authentication-commands
        [string]$ClientId,

        # If specified, skips connecting to Azure and only connects to Microsoft Graph.
        [switch]$SkipAzureConnection,

        # Thumbprint of the certificate to use for authentication. The certificate must be installed in the CurrentUser or LocalMachine certificate store.
        # This parameter is used for app-only authentication (application permissions). ClientId and TenantId are required when using this parameter.
        [string]$CertificateThumbprint,

        # X509Certificate2 certificate object to use for authentication. Alternative to CertificateThumbprint.
        # This parameter is used for app-only authentication (application permissions). ClientId and TenantId are required when using this parameter.
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    Write-Host "`nConnecting to Microsoft Graph" -ForegroundColor Yellow
    Write-PSFMessage 'Connecting to Microsoft Graph'
    try
    {
        $params = @{
            Scopes       = (Get-ZtGraphScope)
            NoWelcome    = $true
            Environment  = $Environment
        }

        if ($UseDeviceCode) {
            $params['UseDeviceCode'] = $true
        }

        # If force use -ContextScope Process to force re-authentication
        if (!$UseTokenCache) {
            $params['ContextScope'] = 'Process'
        }

        if ($TenantId) {
            $params['TenantId'] = $TenantId
        }

        if ($ClientId) {
            $params['ClientId'] = $ClientId
        }

        if ($CertificateThumbprint) {
            if (!$ClientId) {
                throw "ClientId is required when using CertificateThumbprint for certificate authentication."
            }
            if (!$TenantId) {
                throw "TenantId is required when using CertificateThumbprint for certificate authentication."
            }
            $params['CertificateThumbprint'] = $CertificateThumbprint
        }

        if ($Certificate) {
            if (!$ClientId) {
                throw "ClientId is required when using Certificate for certificate authentication."
            }
            if (!$TenantId) {
                throw "TenantId is required when using Certificate for certificate authentication."
            }
            $params['Certificate'] = $Certificate
        }

        Write-PSFMessage "Connecting to Microsoft Graph with params: $($params | Out-String)" -Level Verbose
        Connect-MgGraph @params
        $contextTenantId = (Get-MgContext).TenantId
    }
    catch [Management.Automation.CommandNotFoundException]
    {
        Write-Host "`nThe Graph PowerShell module is not installed. Please install the module using the following command. For more information see https://learn.microsoft.com/powershell/microsoftgraph/installation" -ForegroundColor Red
        Write-Host "`Install-Module Microsoft.Graph -Scope CurrentUser`n" -ForegroundColor Yellow
    }

    if (!$SkipAzureConnection)
    {
        Write-Host "`nConnecting to Azure" -ForegroundColor Yellow
        Write-PSFMessage 'Connecting to Azure'
        try
        {
            $azEnvironment = 'AzureCloud'
            if($Environment -eq 'China') {
                $azEnvironment = Get-AzEnvironment -Name AzureChinaCloud
            }
            elseif($Environment -in 'USGov', 'USGovDoD') {
                $azEnvironment = 'AzureUSGovernment'
            }

            $azParams = @{
                UseDeviceAuthentication = $UseDeviceCode
                Environment = $azEnvironment
                Tenant = if ($TenantId) { $TenantId } else { $contextTenantId }
            }

            Connect-AzAccount @azParams
        }
        catch [Management.Automation.CommandNotFoundException]
        {
            Write-Host "`nThe Azure PowerShell module is not installed. Please install the module using the following command." -ForegroundColor Red
            Write-Host "`Install-Module Az.Accounts -Scope CurrentUser`n" -ForegroundColor Yellow
        }
    }
}
