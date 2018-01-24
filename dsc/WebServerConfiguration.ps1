configuration WebServerConfiguration
{
    node "localhost"
    {
        WindowsFeature WebServerRole
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
		WindowsFeature DotNet35
		{
			Ensure = "Present"
			Name = "Net-Framework-Core"
			Source = "C:\Windows\WinSxS"
		}
		WindowsFeature DotNet45ASPNet
		{
		  Ensure = "Present"
		  Name = "NET-Framework-45-ASPNET"
		}
		WindowsFeature WebASPDotNet45
		{
		  Ensure = "Present"
		  Name = "Web-Asp-Net45"
		}
    }
}

# WebServerConfiguration -OutputPath "C:\DscConfiguration"

# Start-DscConfiguration -Wait -Verbose -Path "C:\DscConfiguration"