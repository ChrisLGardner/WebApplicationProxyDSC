@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'WebApplicationProxyDSC.psm1'

    # Version number of this module.
    ModuleVersion = '1.1.0.0'

    # ID used to uniquely identify this module
    GUID = '286C3120-25E6-4C04-B622-884739DFEB8C'

    # Author of this module
    Author = 'Chris Gardner <chris@blackmarble.co.uk>'

    # Company or vendor of this module
    CompanyName = 'Black Marble'

    # Copyright statement for this module
    Copyright = '(c) 2017 Black Marble. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'This module contains DSC resources that enable configuration of the Web Application Proxy role.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @( 'DSC','DesiredStateConfiguration','DSCResource','WAP','WebApplicationProxy','Proxy','Web','Application')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/ChrisLGardner/WebApplicationProxyDSC/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/ChrisLGardner/WebApplicationProxyDSC'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            #ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # Required for DSC to detect PS class-based resources.
    DscResourcesToExport = @(
        'WapConfiguration'
        )
}  
