configuration IISNet
{ 
    node "localhost"
    {
		# Install IIS
        WindowsFeature IIS 
        { 
            Ensure = "Present" 
            Name = "Web-Server"                       
        }

		# Install ASP.NET 4.5 
		WindowsFeature installdotNet35 
		{             
			Ensure = "Present"
			Name = "Net-Framework-Core"
			Source = "\\neuromancer\Share\Sources_sxs\?Win2012R2"
		} 
	 
		# Install ASP.NET 4.5 
		WindowsFeature ASP 
		{ 
		  Ensure = “Present” 
		  Name = “Web-Asp-Net45” 
		}
    } 
}