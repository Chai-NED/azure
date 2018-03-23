configuration IIS_ASPNet46
{
    node "localhost"
    {
        WindowsFeature WebServerRole
        {
			Ensure = "Present"
			Name = "Web-Server"
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