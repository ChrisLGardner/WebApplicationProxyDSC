enum Ensure {
    Absent
    Present
}

function ConfigureWAP {
	<#
	Function to configure the Web Application Proxy service and connect it to ADFS
	#>
	param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential,
        [Parameter(Mandatory = $true)]
        [string] $CertificateIdentifier,
        [Parameter(Mandatory = $true)]
        [string] $Certificate,
        [Parameter(Mandatory = $true)]
        [string] $FederationServiceName
	)

	$CmdletName = $PSCmdlet.MyInvocation.MyCommand.Name

    Write-Verbose -Message ('Entering function {0}' -f $CmdletName)


		if ($CertificateIdentifier.ToLower() -eq 'subject')
		{

			if ($Certificate.ToLower().Substring(0,3) -ne 'cn=')
			{
			   $CertSubject = "cn=" + $Certificate.ToLower()
			}
			else
			{
				$CertSubject = $Certificate.ToLower()
			}
            $CertificateThumbprint = Get-ChildItem -Path cert:\LocalMachine\My\ |
            where-Object {$_.Subject.ToLower() -eq $CertSubject} |
            Select-Object -ExpandProperty Thumbprint

		}
		else
		{
			$CertificateThumbprint = $Certificate
		}

	Install-WebApplicationProxy -CertificateThumbprint $CertificateThumbprint -FederationServiceName $FederationServiceName -FederationServiceTrustCredential $Credential
}

[DscResource()]
class WapConfiguration
{
    ### Determines whether or not the WAP Config should exist.
    [DscProperty()]
    [Ensure] $Ensure

	<#
    The FederationServiceName property is the name of the Active Directory Federation Services (ADFS) service. For example: adfs-service.contoso.com.
    #>
    [DscProperty(key)]
    [string] $FederationServiceName

	<#
    The Credential property is a PSCredential that represents the username/password of an Active Directory user account that is a member of
    the Domain Administrators security group. This account will be used to add a new proxy to Active Directory Federation Services (ADFS).
    #>
    [DscProperty(Mandatory)]
    [pscredential] $Credential

	<#
    The CertificateIdentifier property can be either 'Subject' or 'Thumbprint' and indicates what the contents of the 'Certificate' property contains.
    #>
    [DscProperty(Mandatory)]
    [string] $CertificateIdentifier

    <#
    The Certificate property is either the Subject Name of the certificate or  the thumbprint of the certificate, located in the local computer's certificate store, that will be bound to the
    Active Directory Federation Service (ADFS) farm.
    #>
    [DscProperty(Mandatory)]
    [string] $Certificate

	[WapConfiguration] Get()
	{
		Write-Verbose -Message 'Starting retrieving Web Application Proxy configuration.'

        try {
            $WapConfiguration= Get-WebApplicationProxyConfiguration -ErrorAction Stop
            $this.Certificate = $WapConfiguration.Certificate
            $this.FederationServiceName = $WapConfiguration.FederationServiceName
        }
        catch {
            Write-Error -Message ('Error occurred while retrieving Web Application Proxy configuration: {0}' -f $global:Error[0].Exception.Message)
        }

        Write-Verbose -Message 'Finished retrieving Web Application Proxy configuration.'
        return $this

	}

	[void] Set()
	{
        ### If WAP shoud be present, then go ahead and configure it.
        if ($this.Ensure -eq [Ensure]::Present) {
            try{
                $WapConfiguration = Get-WebApplicationProxyConfiguration -ErrorAction Stop
            }
            catch {
                $WapConfiguration = $false
            }

            if (!$WapConfiguration) {
                Write-Verbose -Message 'Configuring Web Application Proxy.'
                $WapSettings = @{
                    Credential = $this.Credential
                    CertificateIdentifier = $this.CertificateIdentifier
                    Certificate = $this.Certificate
                    FederationServiceName = $this.FederationServiceName
                }
                ConfigureWAP @WapSettings
            }

            if ($WapConfiguration) {
				#Nothing we can do to reconfigure the service here either, so do nothing
            }
        }

        if ($this.Ensure -eq [Ensure]::Absent) {
            # It is not actually possible to unconfigure WAP, so we do nothing

        }

        return
	}

	[bool] Test()
	{
        # Assume compliance by default
        $Compliant = $true


        Write-Verbose -Message 'Testing for presence of Web Application Proxy.'

        try {
            $WapConfiguration = Get-WebApplicationProxyConfiguration -ErrorAction Stop
        }
        catch {
            $Compliant = $false
            return $Compliant
        }

        if ($this.Ensure -eq 'Present') {
            Write-Verbose -Message 'Checking for correct ADFS service configuration.'

            if (-not($WapConfiguration.ADFSUrl.ToLower() -contains $this.FederationServiceName.ToLower())) {
                Write-Verbose -Message 'ADFS Service Name doesn''t match the desired state.'
                $Compliant = $false
            }
        }

        if ($this.Ensure -eq 'Absent') {
            Write-Verbose -Message 'Checking for absence of WAP Configuration.'
            if ($WapConfiguration) {
                Write-Verbose -Message "WAP Configured but shouldn't be, returning false"
                $Compliant = $false
            }
        }

        return $Compliant
	}

}

[DscResource()]
class WapApplication {

    # Ensure if the application should exist on the node.
    [DscProperty()]
    [Ensure]$Ensure

    # Name of the Application
    [DscProperty(Key)]
    [string]$Name

    [DscProperty()]
    [ValidateSet('PassThrough')]
    [String]$ExternalPreAuthentication

    [DscProperty()]
    [String]$ExternalUrl

    [DscProperty()]
    [String]$ExternalCertificateThumbprint

    [DscProperty()]
    [string]$BackendServerUri

    [DscProperty()]
    [Bool]$EnableSignOut

    [DscProperty()]
    [uint32]$InactiveTransactionsTimeoutSec

    [DscProperty()]
    [string]$ClientCertificatePreauthenticationThumbprint

    [DscProperty()]
    [bool]$EnableHttpRedirect

    [DscProperty()]
    [String]$ADFSUserCertificateStore

    [DscProperty()]
    [bool]$DisableHttpOnlyCookieProtection

    [DscProperty()]
    [Uint32]$PersistentAccessCookieExpirationTimeSec

    [DscProperty()]
    [bool]$DisableTranslateUrlInRequestHeaders

    [DscProperty()]
    [bool]$DisableTranslateUrlInResponseHeaders

    [DscProperty()]
    [String]$BackendServerAuthenticationSPN

    [DscProperty()]
    [String]$ADFSRelyingPartyName

    [DscProperty()]
    [bool]$UseOAuthAuthentication

    [WapApplication]Get() {
        Get-WebApplicationProxyApplication -Name $This.Name
        return $this
    }

    [void]Set() {
        $AddApplicationProperties = @{
            Name = $This.Name
            BackendServerUrl = $This.BackendServerUri
            ExternalCertificateThumbprint = $this.ExternalCertificateThumbprint
            ExternalUrl = $This.ExternalUrl
            ExternalPreAuthentication = $This.ExternalPreAuthentication
        }

        Add-WebApplicationProxyApplication @AddApplicationProperties
    }

    [bool]Test() {
        $Application = Get-WebApplicationProxyApplication -Name $This.Name

        if ($Application) {
            return $true
        }

        return $false
    }

}
