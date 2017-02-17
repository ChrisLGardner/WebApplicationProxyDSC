enum Ensure {
    Absent;
    Present;
}

function ConfigureWAP {
	<#
	Function to configure the Web Application Proxy service and connect it to ADFS
	#>
	param(
        [Parameter(Mandatory = $true)]
        [pscredential] $Credential,
        [Parameter(Mandatory = $true)]
        [string] $CertificateIdentifier,
        [Parameter(Mandatory = $true)]
        [string] $Certificate,
        [Parameter(Mandatory = $true)]
        [string] $FederationServiceName
	)

	$CmdletName = $PSCmdlet.MyInvocation.MyCommand.Name;

    Write-Verbose -Message ('Entering function {0}' -f $CmdletName);


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
			$CertificateThumbprint = (get-childitem -path cert:\LocalMachine\My\ | where {$_.Subject.ToLower() -eq $CertSubject}).Thumbprint

		}
		else
		{
			$CertificateThumbprint = $Certificate
		}

	Install-WebApplicationProxy -CertificateThumbprint $CertificateThumbprint -FederationServiceName $FederationServiceName -FederationServiceTrustCredential $Credential
}

[DscResource()]
class cNewWapConfiguration
{

	<#
    The FederationServiceName property is the name of the Active Directory Federation Services (ADFS) service. For example: adfs-service.contoso.com.
    #>
    [DscProperty(key)]
    [string] $FederationServiceName;

	<#
    The Credential property is a PSCredential that represents the username/password of an Active Directory user account that is a member of
    the Domain Administrators security group. This account will be used to add a new proxy to Active Directory Federation Services (ADFS).
    #>
    [DscProperty(Mandatory)]
    [pscredential] $Credential;

	<#
    The CertificateIdentifier property can be either 'Subject' or 'Thumbprint' and indicates what the contents of the 'Certificate' property contains.
    #>
    [DscProperty(Mandatory)]
    [string] $CertificateIdentifier;

    <#
    The Certificate property is either the Subject Name of the certificate or  the thumbprint of the certificate, located in the local computer's certificate store, that will be bound to the 
    Active Directory Federation Service (ADFS) farm.
    #>
    [DscProperty(Mandatory)]
    [string] $Certificate;

	[cNewWapConfiguration] Get()
	{
		Write-Verbose -Message 'Starting retrieving Web Applucation Proxy configuration.';

        try {
            $WapConfiguration= Get-WebApplicationProxyConfiguration -ErrorAction Stop;
        }
        catch {
            Write-Verbose -Message ('Error occurred while retrieving Web Application Proxy configuration: {0}' -f $global:Error[0].Exception.Message);
        }

        Write-Verbose -Message 'Finished retrieving Web Applucation Proxy configuration.';
        return $this;

	}

	[void] Set()
	{
        ### If WAP shoud be present, then go ahead and configure it.
        if ($this.Ensure -eq [Ensure]::Present) {
            try{
                $WapConfiguration = Get-WebApplicationProxyConfiguration -ErrorAction Stop;
            }
            catch {
                $WapConfiguration = $false
            }

            if (!$WapConfiguration) {
                Write-Verbose -Message 'Configuring Web Application Proxy.';
                $WapSettings = @{
                    Credential = $this.Credential;
                    CertificateIdentifier = $this.CertificateIdentifier;
                    Certificate = $this.Certificate;
                    FederationServiceName = $this.FederationServiceName;
                };
                ConfigureWAP @WapSettings;
            }

            if ($WapConfiguration) {
                Write-Verbose -Message 'Configuring Active Directory Federation Services (ADFS) properties.';
                $AdfsProperties = @{
                    DisplayName = $this.DisplayName;
                };
                Set-AdfsProperties @AdfsProperties;
            }
        }

        if ($this.Ensure -eq [Ensure]::Absent) {
            # It is not actually possible to unconfigure WAP, so we do nothing

        }

        return;
	}

	[bool] Test()
	{
        # Assume compliance by default
        $Compliant = $true;


        Write-Verbose -Message 'Testing for presence of Web Application Proxy.';

        try {
            $WapConfiguration= Get-WebApplicationProxyConfiguration -ErrorAction Stop;
        }
        catch {
            $Compliant = $false;
            return $Compliant;
        }

        if ($this.Ensure -eq 'Present') {
            Write-Verbose -Message 'Checking for correct ADFS service configuration.';
			
            if (-not($Properties.ADFSUrl.ToLower() -contains $this.FederationServiceName.ToLower()) {
                Write-Verbose -Message 'ADFS Service Name doesn''t match the desired state.';
                $Compliant = $false;
            }
        }

        if ($this.Ensure -eq 'Absent') {
            Write-Verbose -Message 'Checking for absence of WAP Configuration.';
            if ($Properties) {
                Write-Verbose -Message
                $Compliant = $false;
            }
        }

        return $Compliant;
	}

}
