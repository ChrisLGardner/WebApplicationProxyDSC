Using Module ..\..\WebApplicationProxyDSC.psd1
Import-Module "$PSScriptRoot\..\..\WebApplicationProxyDSC.psd1" -Force

Function Get-WebApplicationProxyConfiguration {
    [cmdletbinding()]
    Param (
    )
}
Describe 'WapConfiguration -- Testing Get Method' {
    $Sut = [WapConfiguration]::New()

    It 'Should throw when no configuration is available' {
        Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith {Throw 'Nothing to see'}
        {$Sut.Get()} | Should -Throw
    }
    It 'Should call mock' {
        Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith {'Nothing to see'}

        {$Sut.Get()} | Should -Not -Throw

        Assert-MockCalled -CommandName Get-WebApplicationProxyConfiguration -Exactly -Times 1 -Scope It
    }
    It 'Should return object of type WapConfiguration' {
        ($Sut.Get()).GetType().Name | Should -Be 'WapConfiguration'
    }
}

Describe 'WapConfiguration -- Testing Set Method' {
    Mock -CommandName ConfigureWAP -MockWith {}
    $FakeCredentials = New-Object System.Management.Automation.PSCredential ("Username",(ConvertTo-SecureString "Password" -AsPlainText -Force))
    $Sut = [WapConfiguration]::New()
    $Sut.Credential = $FakeCredentials
    $Sut.Certificate = 'TestCertificate'
    $Sut.CertificateIdentifier = 'Subject'
    $Sut.FederationServiceName = 'TestADFS'


    Context 'Ensure Present is set' {
        $Sut.Ensure = [Ensure]::Present

        It 'Should Configure WAP' {
            Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith { Throw 'No WAP'}

            $Sut.Set()

            Assert-MockCalled -CommandName Get-WebApplicationProxyConfiguration -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName ConfigureWAP -Exactly -Times 1 -Scope It
        }
        It 'Should not attempt to reconfigure WAP' {
            Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith { $True }

            $Sut.Set()

            Assert-MockCalled -CommandName Get-WebApplicationProxyConfiguration -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName ConfigureWAP -Exactly -Times 0 -Scope It
        }
    }

    Context 'Ensure Absent is set' {
        $Sut.Ensure = [Ensure]::Absent

        It 'Should not attempt to reconfigure WAP' {
            Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith {}

            $Sut.Set()

            Assert-MockCalled -CommandName Get-WebApplicationProxyConfiguration -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName ConfigureWAP -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'WapConfiguration -- Testing Test Method' {
    $Sut = [WapConfiguration]::New()
    $Sut.FederationServiceName = 'TestADFS'

    It 'Should return False if no WAP configured' {
        Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith { Throw 'No WAP' }

        $Sut.Test() | Should -Be $False
    }
    It 'Should return False if WAP configured with different ADFS url and Ensure is Present' {
        Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith { [psobject]@{ADFSUrl = 'OtherTestADFS'} }

        $Sut.Ensure = [Ensure]::Present

        $Sut.Test() | Should -Be $False

        Assert-MockCalled -CommandName Get-WebApplicationProxyConfiguration -Exactly -Times 1 -Scope It
    }

    It 'Should return False if WAP is configured but Ensure is Absent' {
        Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith { [psobject]@{ADFSUrl = 'OtherTestADFS'} }
        $Sut.Ensure = [Ensure]::Absent

        $Sut.Test() | Should -Be $False
        Assert-MockCalled -CommandName Get-WebApplicationProxyConfiguration -Exactly -Times 1 -Scope It
    }
    It 'Should return True if WAP is not configured and Ensure is Present' {
        Mock -CommandName Get-WebApplicationProxyConfiguration -MockWith { [psobject]@{ADFSUrl = 'TestADFS'} }
        $Sut.Ensure = [Ensure]::Present

        $Sut.Test() | Should -Be $True
    }
}
