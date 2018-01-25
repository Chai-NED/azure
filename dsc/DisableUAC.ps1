# See /ps1-general/InstallVM-PS-DSC-Choco.ps1 for pre-requisites necessary for this to work

Configuration DisableUAC
{
    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -Module xSystemSecurity -Name xUac
 
    node "localhost"
    {
        xUAC NeverNotifyAndDisableAll
        {
            Setting = "NeverNotifyAndDisableAll"
        }
    }
}

# Next two lines for directly invoking on target machine. Comment out if using other deployment technology (DSC pull etc.)
DisableUAC -OutputPath ".\"
Start-DscConfiguration -Wait -Verbose -Path ".\"