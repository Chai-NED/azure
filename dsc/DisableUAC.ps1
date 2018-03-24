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
# DisableUAC -OutputPath ".\"
# Start-DscConfiguration -Wait -Verbose -Path ".\"