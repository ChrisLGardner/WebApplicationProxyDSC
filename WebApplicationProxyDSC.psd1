@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'WebApplicationProxyDSC.psm1'

    # Version number of this module.
    ModuleVersion = '1.1.0.0'

    # ID used to uniquely identify this module
    GUID = '286C3120-25E6-4C04-B622-884739DFEB8C';

    # Author of this module
    Author = 'Rik hepworth <rik@blackmarble.co.uk>';

    # Company or vendor of this module
    CompanyName = 'Black Marble'

    # Copyright statement for this module
    Copyright = '(c) 2017 Black Marble. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'This module contains DSC resources that enable configuration of the Web Application Proxy role.';

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0';

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = '';

    # Required for DSC to detect PS class-based resources.
    DscResourcesToExport = @(
        'WapConfiguration';
        );
}  
